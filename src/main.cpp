#include <Geode/Geode.hpp>
#include <Geode/loader/Setting.hpp>
#include <Geode/modify/PlayLayer.hpp>
#include <Geode/modify/GJBaseGameLayer.hpp>
#include <vector>
#include <string>
#include <algorithm>
#include <cctype>

using namespace geode::prelude;

// Contract:
// - Reads settings: noclipEnabled (bool) and toggleKey (keybind)
// - Listens for keybind to flip noclipEnabled at runtime
// - Hooks PlayLayer::destroyPlayer to skip death if no-clip is enabled
//   Note: This is a minimal / safe hook and not full collision bypass.
//   TODO: For full no-clip, intercept PlayerObject collision resolution functions
//         (e.g., checkCollide, collide, pushButton/releaseButton timing), which
//         depends on bindings available in your Geode version.

namespace
{
    bool g_noclipEnabled = false;
    constexpr int kIndicatorTag = 0xC001F; // unique-ish tag for our overlay label

    void setNoclip(bool enabled)
    {
        g_noclipEnabled = enabled;
        log::info("No-Clip {}", enabled ? "enabled" : "disabled");
        // Persist to settings
        Mod::get()->setSettingValue("noclipEnabled", g_noclipEnabled);

        // Update on-screen indicator if present
        if (auto *bgl = GJBaseGameLayer::get())
        {
            if (auto *node = bgl->getChildByTag(kIndicatorTag))
            {
                if (auto *label = typeinfo_cast<cocos2d::CCLabelBMFont *>(node))
                {
                    label->setString(g_noclipEnabled ? "NC ON" : "NC OFF");
                    cocos2d::ccColor3B col = g_noclipEnabled ? cocos2d::ccColor3B{0, 255, 120}
                                                             : cocos2d::ccColor3B{255, 80, 80};
                    label->setColor(col);
                }
            }
        }
    }

    void toggleNoclip()
    {
        setNoclip(!g_noclipEnabled);
    }
}

// Listen for setting changes when the mod is loaded
$on_mod(Loaded)
{
    // Read initial values
    g_noclipEnabled = Mod::get()->getSettingValue<bool>("noclipEnabled");

    // Listen for setting changes so UI toggles apply immediately
    listenForSettingChanges<bool>(
        "noclipEnabled",
        +[](bool enabled)
        {
            setNoclip(enabled);
        });

    // TODO: Keybind handling
    // Geode core doesn't provide a direct keybind event here. To support a runtime
    // toggle hotkey, either:
    //  - Depend on a keybinds helper mod and listen for its events, or
    //  - Hook a layer method that receives keyboard events (e.g., GJBaseGameLayer::keyDown)
    //    and compare against the configured key.
}

// Minimal hook: skip death when noclip is enabled
// Guard signature to a common 2.2 pattern. If it changes in future SDKs,
// refer to headers Geode/modify/PlayLayer.hpp and adjust.
class $modify(GDNoclip_PlayLayer, PlayLayer)
{
    void onEnter()
    {
        PlayLayer::onEnter();
        // Create indicator once per level
        if (!this->getChildByTag(kIndicatorTag))
        {
            auto *label = cocos2d::CCLabelBMFont::create("NC OFF", "bigFont.fnt");
            auto const winSize = cocos2d::CCDirector::sharedDirector()->getWinSize();
            label->setAnchorPoint({1.f, 1.f});
            label->setScale(0.5f);
            label->setPosition({winSize.width - 10.f, winSize.height - 10.f});
            label->setZOrder(9999);
            label->setTag(kIndicatorTag);
            this->addChild(label);
            // Sync with current setting
            // Reuse setNoclip's UI updater by re-setting the current state
            setNoclip(g_noclipEnabled);
        }
    }

    // In 2.2, destroyPlayer often has signature:
    // void destroyPlayer(PlayerObject* p0, GameObject* p1) or (PlayerObject* p0, void* p1)
    // We mirror the bound one from Geode headers.
    void destroyPlayer(PlayerObject *player, GameObject *obj)
    {
        if (g_noclipEnabled)
        {
            // Skip base implementation; avoid death.
            // Optionally add a small visual/audio cue here.
            return;
        }
        // Call the original
        PlayLayer::destroyPlayer(player, obj);
    }
};

// Hotkey: toggle no-clip when the configured key is pressed in gameplay
class $modify(GDNoclip_GJBaseGameLayer, GJBaseGameLayer)
{
    void keyDown(cocos2d::enumKeyCodes code)
    {
        // List of allowed keys (should match mod.json options)
        static const std::vector<std::string> allowedKeys = {
            "RightShift", "LeftShift", "Space", "A", "S", "D", "F", "Q", "W", "E", "R", "Up", "Down", "Left", "Right"};

        // Get configured keys (comma-separated)
        std::string configured;
        try
        {
            configured = Mod::get()->getSettingValue<std::string>("toggleKey");
        }
        catch (...)
        {
            configured = "RightShift";
        }
        if (configured.empty())
            configured = "RightShift";

        // Split configured keys and normalize
        std::vector<std::string> keys;
        size_t start = 0, end = 0;
        while ((end = configured.find(',', start)) != std::string::npos)
        {
            std::string k = configured.substr(start, end - start);
            k.erase(std::remove_if(k.begin(), k.end(), ::isspace), k.end());
            if (!k.empty())
                keys.push_back(k);
            start = end + 1;
        }
        std::string last = configured.substr(start);
        last.erase(std::remove_if(last.begin(), last.end(), ::isspace), last.end());
        if (!last.empty())
            keys.push_back(last);

        // Validate keys: must be in allowedKeys
        bool valid = true;
        for (const auto &k : keys)
        {
            auto it = std::find(allowedKeys.begin(), allowedKeys.end(), k);
            if (it == allowedKeys.end())
            {
                valid = false;
                break;
            }
        }
        if (!valid || keys.empty())
        {
            log::warn("No-Clip: Invalid or empty toggleKey setting. Falling back to RightShift.");
            keys = {"RightShift"};
        }

        // Convert pressed key to string
        std::string pressed;
        if (auto *disp = cocos2d::CCDirector::sharedDirector()->getKeyboardDispatcher())
        {
            pressed = disp->keyToString(code);
        }

        auto normalize = [](std::string s)
        {
            std::string out;
            out.reserve(s.size());
            for (char c : s)
            {
                if (c != ' ' && c != '_' && c != '-')
                    out.push_back(static_cast<char>(std::tolower(static_cast<unsigned char>(c))));
            }
            return out;
        };

        // Match any configured key
        for (const auto &k : keys)
        {
            if (!pressed.empty() && normalize(pressed) == normalize(k))
            {
                toggleNoclip();
                break;
            }
        }

        GJBaseGameLayer::keyDown(code);
    }
};
