#include <stdio.h>
#include <time.h>

#include "src/Chat.h"
#include "src/Entity.h"
#include "src/Event.h"
#include "src/Server.h"
#include "src/GameStructs.h"
#include "discord_game_sdk/c/discord_game_sdk.h"

#ifdef CC_BUILD_WIN
    #define CC_API __declspec(dllimport)
    #define CC_VAR __declspec(dllimport)
    #define EXPORT __declspec(dllexport)
#else
    #define CC_API
    #define CC_VAR
    #define EXPORT __attribute__((visibility("default")))
#endif

struct Application {
    struct IDiscordCore* core;
    struct IDiscordActivityManager* activities;
};
struct Application app;

static int64_t start_time;
// Get server name only once since long MOTDs can overwrite it later on
static char buffer[64];
static String server_name = String_FromArray(buffer);

static struct EntityVTABLE vtable;
static void (*realPlayerTick)(struct Entity* e, double delta);

static void DiscordPlugin_Tick(struct Entity* e, double delta) {
    realPlayerTick(e, delta);

    // Tick 20 times a second
    app.core->run_callbacks(app.core);
}

static void DiscordPlugin_SetPresence(void) {
    if (!app.activities) return;
    if (start_time == NULL) start_time = time(0);
    if (!server_name.length) String_AppendString(&server_name, &Server.Name);

    struct DiscordActivity activity;
    memset(&activity, 0, sizeof(activity));

    sprintf(activity.assets.large_image, "ccdefault");
    sprintf(activity.assets.large_text, GAME_APP_NAME);
    activity.timestamps.start = start_time;

    if (Server.IsSinglePlayer) {
        sprintf(activity.state, "In Singleplayer");
    } else {
        sprintf(activity.state, "In %s", server_name.buffer);
    }

    app.activities->update_activity(app.activities, &activity, &app, NULL);
}

static void DiscordPlugin_Disconnected(void) {
    // Disable rich presence while the player is disconnected
    app.activities->clear_activity(app.activities, NULL, NULL);
    start_time = NULL;
}

static void DiscordPlugin_Init(void) {
    start_time = time(0);

    // Setup Discord SDK
    memset(&app, 0, sizeof(app));

    struct IDiscordActivityEvents activities_events;
    memset(&activities_events, 0, sizeof(activities_events));

    struct DiscordCreateParams params;
    DiscordCreateParamsSetDefault(&params);
    params.client_id = 378529523089670145;
    params.flags = DiscordCreateFlags_NoRequireDiscord;
    params.activity_events = &activities_events;
    params.event_data = &app;

    if (DiscordCreate(DISCORD_VERSION, &params, &app.core) != DiscordResult_Ok) return;
    
    
    app.activities = app.core->get_activity_manager(app.core);

    Event_RegisterVoid(&NetEvents.Disconnected, NULL, DiscordPlugin_Disconnected);

    // Setup tick by abusing entity ticks
    struct Entity* user = Entities.List[ENTITIES_SELF_ID];
    vtable = *user->VTABLE;
    realPlayerTick = vtable.Tick;
    vtable.Tick  = DiscordPlugin_Tick;
    user->VTABLE = &vtable;
}

EXPORT int Plugin_ApiVersion = 1;
EXPORT struct IGameComponent Plugin_Component = {
    DiscordPlugin_Init, // INIT
    NULL, NULL, NULL, // Free, Reset, OnNewMap
    DiscordPlugin_SetPresence // Using OnNewMapLoaded since OnNewMap gets called on disconnect
};