import Foundation
import Orion

// The fade engine reads crossfade-enable from the persisted prefs; the duration
// slider writes setAudioCrossfadeTime: but never flips audioCrossfade, so it
// stays disabled (gapless). Keep the enable bool in sync with the duration.

struct EeveeCrossfadePrefGroup: HookGroup {}

class PreferencesCrossfadeHook: ClassHook<NSObject> {
    typealias Group = EeveeCrossfadePrefGroup
    static let targetName = "_TtC31Preferences_CorePreferencesImpl28SPTPreferencesImplementation"

    func setAudioCrossfadeTime(_ value: Int) {
        orig.setAudioCrossfadeTime(value)
        orig.setAudioCrossfade(value > 0)
    }

    // Passthrough; declared so orig.setAudioCrossfade is callable above.
    func setAudioCrossfade(_ value: Bool) {
        orig.setAudioCrossfade(value)
    }
}

enum EeveeCrossfade {
    // forced in 9.2's remote configuration (rewriteRemoteConfigurationData), where a Spotify experiment now
    // turns crossfade off: the settings row, the core's own gate, and both sides reading crossfade from the
    // local prefs the hook above keeps in step, rather than the server's playback settings.
    static let replacements = [
        EeveePropertyReplacement(name: "crossfade_enabled", scope: "ios-feature-settings", modification: .forceBool(true)),
        EeveePropertyReplacement(name: "crossfade_enabled", scope: "core-playback-setup", modification: .forceBool(true)),
        EeveePropertyReplacement(name: "use_playback_settings_crossfade", scope: "ios-feature-settings", modification: .forceBool(false)),
        EeveePropertyReplacement(name: "use_playback_settings_crossfade", scope: "playback-settings", modification: .forceBool(false)),
    ]
}

func activateEeveeCrossfadeForce() {
    guard NSClassFromString(PreferencesCrossfadeHook.targetName) != nil else {
        eeveeLog("[EeveeSpotify][Crossfade] Skipped: \(PreferencesCrossfadeHook.targetName) not found")
        return
    }
    EeveeCrossfadePrefGroup().activate()
}

// Playlist Mix ("be your own DJ") gates. 9.2 serves these in the v3 remote
// config, so they must be rewritten there (rewriteRemoteConfigurationData) as
// well as forced at runtime (MixingTools). is_enabled / free_experience_enabled
// are the master gates; debug_bypass_mixability_for_dj lets the editor open
// without the server's mixability metadata. Names taken from 9.2.0.
enum EeveeMixing {
    static let replacements = [
        EeveePropertyReplacement(name: "is_enabled", scope: "ios-playlistcuration-mats", modification: .forceBool(true)),
        EeveePropertyReplacement(name: "free_experience_enabled", scope: "ios-playlistcuration-mats", modification: .forceBool(true)),
        EeveePropertyReplacement(name: "debug_bypass_mixability_for_dj", scope: "ios-playlistcuration-mats", modification: .forceBool(true)),
        EeveePropertyReplacement(name: "backend_auto_transition_enabled", scope: "ios-playlistcuration-mats", modification: .forceBool(true)),
        EeveePropertyReplacement(name: "header_mix_button_enabled", scope: "ios-playlistcuration-mats", modification: .forceBool(true)),
        EeveePropertyReplacement(name: "create_new_mixed_playlist_enabled", scope: "ios-playlistmixing-createmenuitemimpl", modification: .forceBool(true)),
    ]
}
