import '../models/focus_input.dart';

enum AppCategory { productive, neutral, distracting, wellness }

class AppClassifier {
  AppClassifier._();

  static const Set<String> _wellness = {
    'break',
    'idle',
    'idle time',
    'away',
    'rest',
    'stretch',
    'blink',
    'focusflow break',
  };

  static const Set<String> _sharedProductive = {
    'notion',
    'todoist',
    'things',
    'bear',
    'obsidian',
    '1password',
    'bitwarden',
    'zoom',
    'google meet',
    'microsoft teams',
    'teams',
    'slack',
    'linear',
    'jira',
    'confluence',
    'trello',
    'asana',
    'github',
    'gitlab',
    'stackoverflow',
    'stack overflow',
  };

  static const Set<String> _sharedDistracting = {
    'youtube',
    'youtube music',
    'twitter',
    'x',
    'instagram',
    'facebook',
    'tiktok',
    'reddit',
    'snapchat',
    'pinterest',
    'netflix',
    'hulu',
    'disney+',
    'prime video',
    'twitch',
    'kick',
    '9gag',
    'buzzfeed',
  };

  static const Set<String> _windowsProductive = {
    'vs code',
    'vscode',
    'code',
    'visual studio',
    'android studio',
    'intellij idea',
    'intellij',
    'webstorm',
    'pycharm',
    'clion',
    'rider',
    'sublime text',
    'vim',
    'nvim',
    'neovim',
    'emacs',
    'notepad++',
    'cursor',
    'figma',
    'adobe xd',
    'sketch',
    'photoshop',
    'illustrator',
    'premiere pro',
    'after effects',
    'davinci resolve',
    'blender',
    'word',
    'excel',
    'powerpoint',
    'onenote',
    'google docs',
    'google sheets',
    'google slides',
    'libreoffice',
    'terminal',
    'cmd',
    'command prompt',
    'powershell',
    'windows terminal',
    'postman',
    'insomnia',
    'hoppscotch',
    'docker desktop',
    'tableplus',
    'dbeaver',
    'github desktop',
    'sourcetree',
    'fork',
    'wireshark',
    'fiddler',
    'chrome',
    'firefox',
    'edge',
    'safari',
    'arc',
  };

  static const Set<String> _windowsDistracting = {
    'steam',
    'epic games',
    'battle.net',
    'origin',
    'ea app',
    'minecraft',
    'valorant',
    'league of legends',
    'fortnite',
    'genshin impact',
    'counter-strike',
    'cs2',
    'spotify',
    'vlc',
    'windows media player',
    'discord',
    'whatsapp',
    'telegram',
  };

  static const Set<String> _androidProductive = {
    'kindle',
    'google play books',
    'apple books',
    'pocket',
    'instapaper',
    'readwise',
    'duolingo',
    'anki',
    'khan academy',
    'coursera',
    'udemy',
    'brilliant',
    'google docs',
    'google sheets',
    'google slides',
    'microsoft word',
    'microsoft excel',
    'gmail',
    'outlook',
    'google calendar',
    'fantastical',
    'notes',
    'google keep',
    'forest',
    'flora',
    'focusflow',
    'termux',
    'dash',
    'devdocs',
    'tradingview',
    'trading view',
  };

  static const Set<String> _androidDistracting = {
    'instagram',
    'facebook',
    'tiktok',
    'snapchat',
    'twitter',
    'x',
    'reddit',
    'pinterest',
    'whatsapp',
    'telegram',
    'discord',
    'clash of clans',
    'candy crush',
    'subway surfers',
    'mobile legends',
    'pubg mobile',
    'free fire',
    'roblox',
    'among us',
    'netflix',
    'youtube',
    'spotify',
    'twitch',
    'kick',
  };

  static AppCategory classify(String appName, DevicePlatform platform) {
    final name = normalize(appName);

    if (_wellness.contains(name)) return AppCategory.wellness;

    final productiveApps = _productiveSetFor(platform);
    final distractingApps = _distractingSetFor(platform);

    if (productiveApps.contains(name) || _sharedProductive.contains(name)) {
      return AppCategory.productive;
    }

    if (distractingApps.contains(name) || _sharedDistracting.contains(name)) {
      return AppCategory.distracting;
    }

    if (_containsAny(name, productiveApps) ||
        _containsAny(name, _sharedProductive)) {
      return AppCategory.productive;
    }

    if (_containsAny(name, distractingApps) ||
        _containsAny(name, _sharedDistracting)) {
      return AppCategory.distracting;
    }

    return AppCategory.neutral;
  }

  static String categoryName(String appName, DevicePlatform platform) {
    final category = classify(appName, platform);

    return switch (category) {
      AppCategory.productive => 'work',
      AppCategory.neutral => 'neutral',
      AppCategory.distracting => 'entertainment',
      AppCategory.wellness => 'break',
    };
  }

  static int productivityWeight(String appName, DevicePlatform platform) {
    return switch (classify(appName, platform)) {
      AppCategory.productive => 100,
      AppCategory.wellness => 75,
      AppCategory.neutral => 50,
      AppCategory.distracting => 0,
    };
  }

  static bool isProductive(String appName, DevicePlatform platform) {
    return classify(appName, platform) == AppCategory.productive;
  }

  static bool isDistracting(String appName, DevicePlatform platform) {
    return classify(appName, platform) == AppCategory.distracting;
  }

  static bool isWellness(String appName, DevicePlatform platform) {
    return classify(appName, platform) == AppCategory.wellness;
  }

  static bool isNeutral(String appName, DevicePlatform platform) {
    return classify(appName, platform) == AppCategory.neutral;
  }

  static String normalize(String app) {
    final lower = app.toLowerCase().trim();

    return switch (lower) {
      'code.exe' => 'vs code',
      'chrome.exe' => 'chrome',
      'firefox.exe' => 'firefox',
      'discord.exe' => 'discord',
      'figma.exe' => 'figma',
      'winword.exe' => 'word',
      'excel.exe' => 'excel',
      'powerpnt.exe' => 'powerpoint',
      'onenote.exe' => 'onenote',
      'msedge.exe' => 'edge',
      'cmd.exe' => 'cmd',
      'powershell.exe' => 'powershell',
      'windowsterminal.exe' => 'windows terminal',
      _ =>
        lower.endsWith('.exe') ? lower.substring(0, lower.length - 4) : lower,
    };
  }

  static Set<String> _productiveSetFor(DevicePlatform platform) {
    return switch (platform) {
      DevicePlatform.windows => _windowsProductive,
      DevicePlatform.android => _androidProductive,
      DevicePlatform.tablet => {..._androidProductive, ..._sharedProductive},
      DevicePlatform.web => {..._windowsProductive, ..._sharedProductive},
    };
  }

  static Set<String> _distractingSetFor(DevicePlatform platform) {
    return switch (platform) {
      DevicePlatform.windows => _windowsDistracting,
      DevicePlatform.android => _androidDistracting,
      DevicePlatform.tablet => {..._androidDistracting, ..._sharedDistracting},
      DevicePlatform.web => {..._windowsDistracting, ..._sharedDistracting},
    };
  }

  static bool _containsAny(String appName, Set<String> candidates) {
    return candidates.any(
      (candidate) =>
          candidate.length >= 4 &&
          (appName.contains(candidate) || candidate.contains(appName)),
    );
  }
}
