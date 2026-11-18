import SwiftUI

struct SpotifyFeaturesView: View {
    @State private var version = 0
    @State private var hideJam = UserDefaults.hideJam
    @State private var mixingTools = UserDefaults.mixingTools
    @State private var flagsDefault = FlagOverrides.areDefault(SpotifyFeaturesView.keys)

    private static let sections: [(header: String, rows: [(String, String)])] = [
        ("features_playback", [
            ("features_trim_silence", "ios-playbackcontrol-playbackspeed-impl.enable_trim_silence"),
        ]),
        ("features_library", [
            ("features_recents", "ios-feature-yourlibaryx.recents_enabled"),
            ("features_recents_sort", "ios-feature-yourlibaryx.recents_sort_order_enabled"),
            ("features_sort_playlists", "ios-feature-yourlibaryx.recently_updated_playlists_sort_enabled"),
            ("features_sort_artists", "ios-feature-yourlibaryx.recently_updated_artists_sort_enabled"),
            ("features_denser_rows", "ios-feature-yourlibaryx.denser_rows_enabled"),
            ("features_library_settings", "ios-feature-yourlibaryx.library_settings_enabled"),
            ("features_library_pro", "ios-feature-yourlibaryx.your_library_pro_enabled"),
            ("features_shake_random", "ios-feature-yourlibaryx.shake_to_random_enabled"),
        ]),
        ("features_lockscreen", [
            ("features_lock_like", "ios-feature-lockscreen.like_dislike_enabled"),
            ("features_lock_podcast_skip", "ios-feature-lockscreen.skip_button_on_podcasts"),
            ("features_lock_chapters", "ios-feature-lockscreen.enable_chapter_skip_controls"),
            ("features_lock_animated", "ios-feature-lockscreen.animated_artwork_enabled"),
        ]),
        ("features_sleep_timer", [
            ("features_sleep_fade", "ios-feature-sleeptimer.enable_fade_out"),
            ("features_sleep_one_minute", "ios-feature-sleeptimer.enable_one_minute_option"),
        ]),
        ("features_home", [
            ("features_dj_button", "ios-home-evopage-impl.idj_show_dj_button"),
            ("features_dj_badge", "ios-home-evopage-impl.dj_mdc_beta_badge_enabled"),
        ]),
        ("features_other", [
            ("features_local_files", "ios-feature-localfiles.documents_enabled"),
        ]),
    ]

    private static var keys: [String] { sections.flatMap { $0.rows.map(\.1) } }

    var body: some View {
        List {
            ForEach(Self.sections, id: \.header) { section in
                Section(header: Text(section.header.localized)) {
                    ForEach(section.rows, id: \.1) { FlagOverrideRow(title: $0.0.localized, key: $0.1) { version += 1 } }
                }
            }
            .id(version)

            Section(footer: Text("features_hide_jam_footer".localized)) {
                Toggle("features_hide_jam".localized, isOn: $hideJam)
            }

            Section(footer: Text("features_mixing_footer".localized)) {
                Toggle("features_mixing".localized, isOn: $mixingTools)
            }

            SettingsResetSection(visible: hideJam || !mixingTools || !flagsDefault) {
                hideJam = false
                mixingTools = true
                FlagOverrides.clear(Self.keys)
                version += 1
            }

            if RemoteFlags.needsRestart || hideJam != HideJam.launchEnabled || mixingTools != MixingTools.launchEnabled {
                Section {
                    Button(action: exitApplication) {
                        Text("restart_now".localized).fontWeight(.semibold).frame(maxWidth: .infinity)
                    }
                    .foregroundColor(EeveeTheme.accent)
                }
            }

            SpacerView()
        }
        .eeveeSettingsStyle()
        .onChange(of: hideJam) { UserDefaults.hideJam = $0 }
        .onChange(of: mixingTools) { UserDefaults.mixingTools = $0 }
        .onAppear(perform: refreshFlags)
        .onChange(of: version) { _ in refreshFlags() }
    }

    private func refreshFlags() {
        flagsDefault = FlagOverrides.areDefault(Self.keys)
    }
}

enum HideJam {
    static let launchEnabled = UserDefaults.hideJam

    private static let flags = [
        "ios-feature-nowplaying.jam_queue_button_enabled",
        "ios-referrals-jamqueueentrypointimpl.referrals_jam_queue_enabled",
        "ios-jam-queueintegrationimpl.enable_guest_controls_queue_header_entry_point",
        "ios-sociallistening-attachments-impl.enable_group_session_attachment",
        "ios-feature-sociallisteningconnectentitylogic.enable_phone_speaker_host_approval",
        "ios-feature-sociallisteningconnectentitylogic.enable_host_approval_flow",
        "ios-feature-jamdevicepickerintegration.enable_host_approval_flow",
        "ios-feature-sociallisteningconnectentitylogic.show_nearby_jam_nudge",
        "ios-feature-sociallisteningconnectentitylogic.nearby_session_invitation_enabled",
        "ios-feature-sociallisteningconnectentitylogic.nearby_session_enable_visibility_filter",
        "ios-sociallistening-joingroupsession-impl.jam_deeplink_handler_enabled",
        "ios-sociallistening-joingroupsession-impl.is_nearby_jam_invite_deeplink_enabled",
        "ios-feature-jamuiimpl.enable_deeplink_flow",
        "ios-sociallistening-localnetworkbroadcasting.enable_broadcasting",
        "ios-sociallistening-localnetworksessionfinder.enable_discovery_v2",
        "ios-jam-participantsettingspageimpl.enable_guest_controls_sheet",
        "ios-jam-learnmoresheet.enable_invites_learn_more_sheet",
    ]

    static func activate() {
        guard launchEnabled else { return }
        RemoteFlags.shared.force(Dictionary(uniqueKeysWithValues: flags.map { ($0, false) }), by: "HideJam")
    }
}

// Forces the client-side flags that expose Spotify's playlist Mix tools (the
// beat/key editor) on accounts the server doesn't hand them to. The analysis
// data itself (BPM, Camelot key, beat grid) is available to free accounts via
// spclient; these flags only decide whether the UI reads and shows it.
enum MixingTools {
    static let launchEnabled = UserDefaults.mixingTools

    private static let flags: [String: Bool] = [
        // master gates (the ones that actually decide whether Mix is offered)
        "ios-playlistcuration-mats.is_enabled": true,
        "ios-playlistcuration-mats.free_experience_enabled": true,
        "ios-playlistcuration-mats.debug_bypass_mixability_for_dj": true,
        "ios-playlistcuration-mats.backend_auto_transition_enabled": true,
        "ios-playlistcuration-mats.header_mix_button_enabled": true,
        "ios-playlistcuration-mats.playlist_reordering_for_mix_entrypoint_enabled": true,
        "ios-playlistmixing-createmenuitemimpl.create_new_mixed_playlist_enabled": true,
        "ios-playlistmixing-createmenuitemimpl.beta_tag_enabled": false,

        // Every other Mix-related switch the client actually reads on 9.2.0.
        // Catalogued from the device's own remote-flag log; the playlist Mix
        // editor was still reporting permission `none` with these left at false.
        "ios-list-ux-platform-consumers-extender.mixed_playlist_endpoint_enabled": true,
        "ios-feature-magpie.mixing_enabled": true,
        "ios-feature-magpie.mixing_warning_dialog_enabled": true,
        "ios-feature-nowplaying-elements.mixing_play_button": true,
        "ios-feature-settings.automix_enabled": true,
        "ios-feature-search.instant_mix_section_enabled": true,
        "ios-feature-search.instant_mix_section_animation_enabled": true,
        "ios-feature-search.instant_mix_section_ai_branding_enabled": true,
        "ios-feature-search.instant_mix_ux_in_serp_enabled": true,
        "ios-feature-search.optimized_instant_mix_section_enabled": true,
        "ios-feature-search.simplified_instant_mix_row_enabled": true,
        "ios-playlistcuration-mats.auto_mix_enabled_for_dj": true,
        "ios-playlistcuration-mats.automix_track_order_context_menu_enabled": true,
        "ios-playlistcuration-mats.dj_auto_mix_context_menu_enabled": true,
        "ios-playlistcuration-mats.opt_in_new_effects_enabled": true,
        "ios-playlistcuration-mats.smart_reorder_on_auto_mix_enabled": true,
        "ios-playlistcuration-mats.third_party_mix_snackbar_enabled": true,
    ]

    static func activate() {
        guard launchEnabled else { return }
        RemoteFlags.shared.force(flags, by: "MixingTools")
        dumpMixCatalog()
    }

    // The remote-config catalog already holds every switch Spotify has asked for
    // on this device, so this prints the real names of the Mix permission gates
    // instead of us guessing them from the binary.
    private static func dumpMixCatalog() {
        let hits = RemoteFlags.shared.loadCatalog().filter {
            let key = $0.key.lowercased()
            return key.contains("mix") || key.contains("permission")
                || key.contains("opt-in") || key.contains("opt_in")
        }
        let pairs = hits.prefix(100).map { "\($0.key)=\($0.value)" }
        eeveeLog("[EeveeSpotify][Mix] catalog hits %d: %@", hits.count, pairs.joined(separator: " | "))
    }
}

extension UserDefaults {
    static var hideJam: Bool {
        get { container.bool(forKey: "eeveeHideJam") }
        set { container.set(newValue, forKey: "eeveeHideJam") }
    }

    static var mixingTools: Bool {
        get { container.object(forKey: "eeveeMixingTools") as? Bool ?? true }
        set { container.set(newValue, forKey: "eeveeMixingTools") }
    }
}
