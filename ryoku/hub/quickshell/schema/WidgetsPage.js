.pragma library

var rows = [
    {
        "tab": "clock",
        "group": "WIDGET",
        "key": "clockEnabled",
        "label": "Enabled",
        "desc": "Shows the clock; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "clock",
        "group": "WIDGET",
        "key": "clockDesign",
        "label": "Face",
        "desc": "How the time is drawn: digits, analog, flip and more",
        "ctl": "chips",
        "src": "widgets.json",
        "opts": [
            "digital",
            "minimal",
            "grand",
            "column",
            "outline",
            "banner",
            "analog",
            "flip",
            "rings",
            "bighour",
            "metal",
            "goodnight"
        ]
    },
    {
        "tab": "clock",
        "group": "WIDGET",
        "key": "clockAccent",
        "label": "Accent",
        "desc": "Palette follows the wallpaper; mono stays grey",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "palette",
            "brand",
            "mono"
        ]
    },
    {
        "tab": "clock",
        "group": "WIDGET",
        "key": "widgetFont",
        "label": "Widget font",
        "desc": "Font for every desktop widget; blank uses Space Grotesk",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": []
    },
    {
        "tab": "clock",
        "group": "TIME & DATE",
        "key": "clock24h",
        "label": "24-hour clock",
        "desc": "Shows 14:30 rather than 2:30 pm on the face",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "clock",
        "group": "TIME & DATE",
        "key": "clockSeconds",
        "label": "Show seconds",
        "desc": "Adds seconds to the readout; the face ticks each second",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "clock",
        "group": "TIME & DATE",
        "key": "dateShow",
        "label": "Show date",
        "desc": "Adds today's date beside or under the time",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "clock",
        "group": "TIME & DATE",
        "key": "dateDesign",
        "label": "Date style",
        "desc": "How the date sits with the time: inline, badge or stacked",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "inline",
            "badge",
            "stacked"
        ]
    },
    {
        "tab": "clock",
        "group": "SIZE & SHAPE",
        "key": "clockScale",
        "label": "Size",
        "desc": "Scales the clock; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "clock",
        "group": "SIZE & SHAPE",
        "key": "clockBg",
        "label": "Background",
        "desc": "Panel behind the clock; none sits on the wallpaper",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "none",
            "card",
            "glass"
        ]
    },
    {
        "tab": "clock",
        "group": "SIZE & SHAPE",
        "key": "clockRadius",
        "label": "Corner radius",
        "desc": "Rounds the panel corners; needs a card or glass background",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 60.0,
        "unit": "px",
        "when": {
            "clockBg": [
                "card",
                "glass"
            ]
        }
    },
    {
        "tab": "clock",
        "group": "SIZE & SHAPE",
        "key": "clockOpacity",
        "label": "Opacity",
        "desc": "Fades the clock; a floor keeps it from vanishing",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "clock",
        "group": "PLACEMENT",
        "key": "clockAnchor",
        "label": "Anchor",
        "desc": "Where the clock sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "clock",
        "group": "PLACEMENT",
        "key": "clockX",
        "label": "X",
        "desc": "Clock's distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "clockAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "clock",
        "group": "PLACEMENT",
        "key": "clockY",
        "label": "Y",
        "desc": "Clock's distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "clockAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "clock",
        "group": "PLACEMENT",
        "key": "clockLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging the clock on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "calendar",
        "group": "WIDGET",
        "key": "calendarEnabled",
        "label": "Enabled",
        "desc": "Shows the calendar; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "calendar",
        "group": "WIDGET",
        "key": "calendarStyle",
        "label": "Style",
        "desc": "Glass follows the wallpaper tint; Paper is opaque",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "glass",
            "paper"
        ]
    },
    {
        "tab": "calendar",
        "group": "CALENDAR",
        "key": "calendarWeeks",
        "label": "Minimum weeks",
        "desc": "Fewest week rows; the view grows when a month needs more",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 4,
        "hi": 8
    },
    {
        "tab": "calendar",
        "group": "CALENDAR",
        "key": "calendarWeekNumbers",
        "label": "ISO week numbers",
        "desc": "Adds the week-of-year column left of the grid",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "calendar",
        "group": "CALENDAR",
        "key": "calendarHolidayRegion",
        "label": "Holiday region",
        "desc": "Blank uses your locale; else a code like US or US-CA",
        "ctl": "text",
        "src": "widgets.json"
    },
    {
        "tab": "calendar",
        "group": "SIZE & SHAPE",
        "key": "calendarScale",
        "label": "Size",
        "desc": "Scales the calendar; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.0
    },
    {
        "tab": "calendar",
        "group": "SIZE & SHAPE",
        "key": "calendarOpacity",
        "label": "Opacity",
        "desc": "Fades the calendar while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "calendar",
        "group": "PLACEMENT",
        "key": "calendarAnchor",
        "label": "Anchor",
        "desc": "Where the calendar sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "calendar",
        "group": "PLACEMENT",
        "key": "calendarX",
        "label": "X",
        "desc": "Calendar's distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0,
        "hi": 5000,
        "unit": "px",
        "when": {
            "calendarAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "calendar",
        "group": "PLACEMENT",
        "key": "calendarY",
        "label": "Y",
        "desc": "Calendar's distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0,
        "hi": 5000,
        "unit": "px",
        "when": {
            "calendarAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "calendar",
        "group": "PLACEMENT",
        "key": "calendarLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging the calendar on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "music",
        "group": "WIDGET",
        "key": "musicEnabled",
        "label": "Enabled",
        "desc": "Shows the now-playing sheet; settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "music",
        "group": "WIDGET",
        "key": "musicStyle",
        "label": "Style",
        "desc": "Cover wears the album colour; Glass is a frosted pane",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "cover",
            "glass"
        ]
    },
    {
        "tab": "music",
        "group": "WIDGET",
        "key": "musicLyrics",
        "label": "Lyrics",
        "desc": "Shows synced lyrics beside the album when found",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "music",
        "group": "WIDGET",
        "key": "musicViz",
        "label": "Visualiser",
        "desc": "Shown when a track has no lyrics: Bars or Wave",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "bars",
            "wave"
        ]
    },
    {
        "tab": "music",
        "group": "WIDGET",
        "key": "musicApp",
        "label": "Music app",
        "desc": "App the corner button opens; blank uses ryotunes",
        "ctl": "app",
        "src": "widgets.json"
    },
    {
        "tab": "music",
        "group": "SIZE & SHAPE",
        "key": "musicScale",
        "label": "Size",
        "desc": "Scales the music sheet; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.0
    },
    {
        "tab": "music",
        "group": "SIZE & SHAPE",
        "key": "musicOpacity",
        "label": "Opacity",
        "desc": "Fades the music sheet while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "music",
        "group": "PLACEMENT",
        "key": "musicAnchor",
        "label": "Anchor",
        "desc": "Where the music sheet sits; Auto picks, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "music",
        "group": "PLACEMENT",
        "key": "musicX",
        "label": "X",
        "desc": "Music sheet's distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0,
        "hi": 5000,
        "unit": "px",
        "when": {
            "musicAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "music",
        "group": "PLACEMENT",
        "key": "musicY",
        "label": "Y",
        "desc": "Music sheet's distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0,
        "hi": 5000,
        "unit": "px",
        "when": {
            "musicAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "music",
        "group": "PLACEMENT",
        "key": "musicLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging the music sheet on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "aio",
        "group": "WIDGET",
        "key": "aioEnabled",
        "label": "Enabled",
        "desc": "Shows the weather-and-clock card; settings kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "aio",
        "group": "WIDGET",
        "key": "aioStyle",
        "label": "Layout",
        "desc": "Wide is a landscape card; Tall a portrait panel",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "wide",
            "tall"
        ]
    },
    {
        "tab": "aio",
        "group": "SIZE & SHAPE",
        "key": "aioScale",
        "label": "Size",
        "desc": "Scales the card; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.0
    },
    {
        "tab": "aio",
        "group": "SIZE & SHAPE",
        "key": "aioOpacity",
        "label": "Opacity",
        "desc": "Fades the card while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "aio",
        "group": "PLACEMENT",
        "key": "aioAnchor",
        "label": "Anchor",
        "desc": "Where the card sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "aio",
        "group": "PLACEMENT",
        "key": "aioX",
        "label": "X",
        "desc": "Card's distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0,
        "hi": 5000,
        "unit": "px",
        "when": {
            "aioAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "aio",
        "group": "PLACEMENT",
        "key": "aioY",
        "label": "Y",
        "desc": "Card's distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0,
        "hi": 5000,
        "unit": "px",
        "when": {
            "aioAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "aio",
        "group": "PLACEMENT",
        "key": "aioLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging the card on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "stats",
        "group": "WIDGET",
        "key": "statsEnabled",
        "label": "Enabled",
        "desc": "Shows the system-stats panel; settings kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "stats",
        "group": "SIZE & SHAPE",
        "key": "statsScale",
        "label": "Size",
        "desc": "Scales the stats panel; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.0
    },
    {
        "tab": "stats",
        "group": "SIZE & SHAPE",
        "key": "statsOpacity",
        "label": "Opacity",
        "desc": "Fades the stats panel while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "stats",
        "group": "PLACEMENT",
        "key": "statsAnchor",
        "label": "Anchor",
        "desc": "Where the panel sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "stats",
        "group": "PLACEMENT",
        "key": "statsX",
        "label": "X",
        "desc": "Stats panel's distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0,
        "hi": 5000,
        "unit": "px",
        "when": {
            "statsAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "stats",
        "group": "PLACEMENT",
        "key": "statsY",
        "label": "Y",
        "desc": "Stats panel's distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0,
        "hi": 5000,
        "unit": "px",
        "when": {
            "statsAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "stats",
        "group": "PLACEMENT",
        "key": "statsLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging the stats panel on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "weather",
        "group": "WIDGET",
        "key": "weatherEnabled",
        "label": "Enabled",
        "desc": "Shows the weather; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "weather",
        "group": "WIDGET",
        "key": "weatherDesign",
        "label": "Layout",
        "desc": "Compact is glyph, temp and city; Full adds much more",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "compact",
            "full"
        ]
    },
    {
        "tab": "weather",
        "group": "SIZE & SHAPE",
        "key": "weatherScale",
        "label": "Size",
        "desc": "Scales the weather widget; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "weather",
        "group": "SIZE & SHAPE",
        "key": "weatherOpacity",
        "label": "Opacity",
        "desc": "Fades the weather widget while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "weather",
        "group": "PLACEMENT",
        "key": "weatherAnchor",
        "label": "Anchor",
        "desc": "Where weather sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "weather",
        "group": "PLACEMENT",
        "key": "weatherX",
        "label": "X",
        "desc": "Weather's distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0,
        "hi": 5000,
        "unit": "px",
        "when": {
            "weatherAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "weather",
        "group": "PLACEMENT",
        "key": "weatherY",
        "label": "Y",
        "desc": "Weather's distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0,
        "hi": 5000,
        "unit": "px",
        "when": {
            "weatherAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "weather",
        "group": "PLACEMENT",
        "key": "weatherLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging weather on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "notes",
        "group": "WIDGET",
        "key": "notesEnabled",
        "label": "Enabled",
        "desc": "Shows the scratch pad; the note is kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "notes",
        "group": "SIZE & SHAPE",
        "key": "notesWidth",
        "label": "Width",
        "desc": "Pad width in pixels, before Size scales it",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 160,
        "hi": 900,
        "unit": "px"
    },
    {
        "tab": "notes",
        "group": "SIZE & SHAPE",
        "key": "notesHeight",
        "label": "Height",
        "desc": "Pad height in pixels, before Size scales it",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 120,
        "hi": 900,
        "unit": "px"
    },
    {
        "tab": "notes",
        "group": "SIZE & SHAPE",
        "key": "notesScale",
        "label": "Size",
        "desc": "Scales the pad's width, height and text together",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "notes",
        "group": "SIZE & SHAPE",
        "key": "notesOpacity",
        "label": "Opacity",
        "desc": "Fades the pad while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "notes",
        "group": "PLACEMENT",
        "key": "notesAnchor",
        "label": "Anchor",
        "desc": "Where the pad sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "notes",
        "group": "PLACEMENT",
        "key": "notesX",
        "label": "X",
        "desc": "Notes pad's distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0,
        "hi": 5000,
        "unit": "px",
        "when": {
            "notesAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "notes",
        "group": "PLACEMENT",
        "key": "notesY",
        "label": "Y",
        "desc": "Notes pad's distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0,
        "hi": 5000,
        "unit": "px",
        "when": {
            "notesAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "notes",
        "group": "PLACEMENT",
        "key": "notesLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging the pad on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "dayprogress",
        "group": "WIDGET",
        "key": "dayprogressEnabled",
        "label": "Enabled",
        "desc": "Shows the day-progress ring; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "dayprogress",
        "group": "WIDGET",
        "key": "dayprogressStyle",
        "label": "Style",
        "desc": "Ring keeps the track behind the fill; Arc drops it",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "ring",
            "arc"
        ]
    },
    {
        "tab": "dayprogress",
        "group": "WIDGET",
        "key": "dayprogressShowDate",
        "label": "Show date",
        "desc": "Prints today's date under the ring",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "dayprogress",
        "group": "SIZE & SHAPE",
        "key": "dayprogressScale",
        "label": "Size",
        "desc": "Scales the ring; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "dayprogress",
        "group": "SIZE & SHAPE",
        "key": "dayprogressOpacity",
        "label": "Opacity",
        "desc": "Fades the ring while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "dayprogress",
        "group": "PLACEMENT",
        "key": "dayprogressAnchor",
        "label": "Anchor",
        "desc": "Where the ring sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "dayprogress",
        "group": "PLACEMENT",
        "key": "dayprogressX",
        "label": "X",
        "desc": "Ring's distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0,
        "hi": 5000,
        "unit": "px",
        "when": {
            "dayprogressAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "dayprogress",
        "group": "PLACEMENT",
        "key": "dayprogressY",
        "label": "Y",
        "desc": "Ring's distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0,
        "hi": 5000,
        "unit": "px",
        "when": {
            "dayprogressAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "dayprogress",
        "group": "PLACEMENT",
        "key": "dayprogressLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging the ring on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "shape",
        "group": "WIDGET",
        "key": "shapeEnabled",
        "label": "Enabled",
        "desc": "Shows the decorative shape; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "shape",
        "group": "WIDGET",
        "key": "shapeKind",
        "label": "Shape",
        "desc": "The form drawn: dot, ring, diamond or square",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "dot",
            "ring",
            "diamond",
            "square"
        ]
    },
    {
        "tab": "shape",
        "group": "WIDGET",
        "key": "shapeOutline",
        "label": "Outline",
        "desc": "Draws the shape as a hairline instead of a fill",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "shape",
        "group": "SIZE & SHAPE",
        "key": "shapeScale",
        "label": "Size",
        "desc": "Scales the shape; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "shape",
        "group": "SIZE & SHAPE",
        "key": "shapeOpacity",
        "label": "Opacity",
        "desc": "Fades the shape",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "shape",
        "group": "PLACEMENT",
        "key": "shapeAnchor",
        "label": "Anchor",
        "desc": "Where the shape sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "shape",
        "group": "PLACEMENT",
        "key": "shapeX",
        "label": "X",
        "desc": "Shape's distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0,
        "hi": 5000,
        "unit": "px",
        "when": {
            "shapeAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "shape",
        "group": "PLACEMENT",
        "key": "shapeY",
        "label": "Y",
        "desc": "Shape's distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0,
        "hi": 5000,
        "unit": "px",
        "when": {
            "shapeAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "shape",
        "group": "PLACEMENT",
        "key": "shapeLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging the shape on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "irisClock",
        "group": "WIDGET",
        "key": "irisClockEnabled",
        "label": "Enabled",
        "desc": "Shows this face; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "irisClock",
        "group": "WIDGET",
        "key": "irisClockStyle",
        "label": "Style",
        "desc": "iNiR draws the face upstream; Ryoku is the paper skin",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "inir",
            "ryoku"
        ]
    },
    {
        "tab": "irisClock",
        "group": "WIDGET",
        "key": "irisClockSize",
        "label": "Size preset",
        "desc": "The face's own iRiS layout size",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "small",
            "medium"
        ]
    },
    {
        "tab": "irisClock",
        "group": "SIZE & SHAPE",
        "key": "irisClockBg",
        "label": "Background",
        "desc": "Ryoku-style backing behind the face; none sits bare",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "none",
            "card",
            "glass"
        ]
    },
    {
        "tab": "irisClock",
        "group": "SIZE & SHAPE",
        "key": "irisClockRadius",
        "label": "Corner radius",
        "desc": "Rounds the backing (and the iNiR plate); 0 is square",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 120.0,
        "unit": "px"
    },
    {
        "tab": "irisClock",
        "group": "SIZE & SHAPE",
        "key": "irisClockScale",
        "label": "Size",
        "desc": "Scales the face; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "irisClock",
        "group": "SIZE & SHAPE",
        "key": "irisClockOpacity",
        "label": "Opacity",
        "desc": "Fades the face while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "irisClock",
        "group": "PLACEMENT",
        "key": "irisClockAnchor",
        "label": "Anchor",
        "desc": "Where the face sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "irisClock",
        "group": "PLACEMENT",
        "key": "irisClockX",
        "label": "X",
        "desc": "Distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisClockAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisClock",
        "group": "PLACEMENT",
        "key": "irisClockY",
        "label": "Y",
        "desc": "Distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisClockAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisClock",
        "group": "PLACEMENT",
        "key": "irisClockLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging this face on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "irisWeather",
        "group": "WIDGET",
        "key": "irisWeatherEnabled",
        "label": "Enabled",
        "desc": "Shows this face; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "irisWeather",
        "group": "WIDGET",
        "key": "irisWeatherStyle",
        "label": "Style",
        "desc": "iNiR draws the face upstream; Ryoku is the paper skin",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "inir",
            "ryoku"
        ]
    },
    {
        "tab": "irisWeather",
        "group": "WIDGET",
        "key": "irisWeatherSize",
        "label": "Size preset",
        "desc": "The face's own iRiS layout size",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "small",
            "medium",
            "large"
        ]
    },
    {
        "tab": "irisWeather",
        "group": "SIZE & SHAPE",
        "key": "irisWeatherBg",
        "label": "Background",
        "desc": "Ryoku-style backing behind the face; none sits bare",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "none",
            "card",
            "glass"
        ]
    },
    {
        "tab": "irisWeather",
        "group": "SIZE & SHAPE",
        "key": "irisWeatherRadius",
        "label": "Corner radius",
        "desc": "Rounds the backing (and the iNiR plate); 0 is square",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 120.0,
        "unit": "px"
    },
    {
        "tab": "irisWeather",
        "group": "SIZE & SHAPE",
        "key": "irisWeatherScale",
        "label": "Size",
        "desc": "Scales the face; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "irisWeather",
        "group": "SIZE & SHAPE",
        "key": "irisWeatherOpacity",
        "label": "Opacity",
        "desc": "Fades the face while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "irisWeather",
        "group": "PLACEMENT",
        "key": "irisWeatherAnchor",
        "label": "Anchor",
        "desc": "Where the face sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "irisWeather",
        "group": "PLACEMENT",
        "key": "irisWeatherX",
        "label": "X",
        "desc": "Distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisWeatherAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisWeather",
        "group": "PLACEMENT",
        "key": "irisWeatherY",
        "label": "Y",
        "desc": "Distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisWeatherAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisWeather",
        "group": "PLACEMENT",
        "key": "irisWeatherLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging this face on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "irisMedia",
        "group": "WIDGET",
        "key": "irisMediaEnabled",
        "label": "Enabled",
        "desc": "Shows this face; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "irisMedia",
        "group": "WIDGET",
        "key": "irisMediaStyle",
        "label": "Style",
        "desc": "iNiR draws the face upstream; Ryoku is the paper skin",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "inir",
            "ryoku"
        ]
    },
    {
        "tab": "irisMedia",
        "group": "WIDGET",
        "key": "irisMediaSize",
        "label": "Size preset",
        "desc": "The face's own iRiS layout size",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "small",
            "medium",
            "large"
        ]
    },
    {
        "tab": "irisMedia",
        "group": "SIZE & SHAPE",
        "key": "irisMediaBg",
        "label": "Background",
        "desc": "Ryoku-style backing behind the face; none sits bare",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "none",
            "card",
            "glass"
        ]
    },
    {
        "tab": "irisMedia",
        "group": "SIZE & SHAPE",
        "key": "irisMediaRadius",
        "label": "Corner radius",
        "desc": "Rounds the backing (and the iNiR plate); 0 is square",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 120.0,
        "unit": "px"
    },
    {
        "tab": "irisMedia",
        "group": "SIZE & SHAPE",
        "key": "irisMediaScale",
        "label": "Size",
        "desc": "Scales the face; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "irisMedia",
        "group": "SIZE & SHAPE",
        "key": "irisMediaOpacity",
        "label": "Opacity",
        "desc": "Fades the face while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "irisMedia",
        "group": "PLACEMENT",
        "key": "irisMediaAnchor",
        "label": "Anchor",
        "desc": "Where the face sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "irisMedia",
        "group": "PLACEMENT",
        "key": "irisMediaX",
        "label": "X",
        "desc": "Distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisMediaAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisMedia",
        "group": "PLACEMENT",
        "key": "irisMediaY",
        "label": "Y",
        "desc": "Distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisMediaAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisMedia",
        "group": "PLACEMENT",
        "key": "irisMediaLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging this face on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "irisControls",
        "group": "WIDGET",
        "key": "irisControlsEnabled",
        "label": "Enabled",
        "desc": "Shows this face; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "irisControls",
        "group": "WIDGET",
        "key": "irisControlsStyle",
        "label": "Style",
        "desc": "iNiR draws the face upstream; Ryoku is the paper skin",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "inir",
            "ryoku"
        ]
    },
    {
        "tab": "irisControls",
        "group": "WIDGET",
        "key": "irisControlsSize",
        "label": "Size preset",
        "desc": "The face's own iRiS layout size",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "small",
            "medium",
            "large"
        ]
    },
    {
        "tab": "irisControls",
        "group": "SIZE & SHAPE",
        "key": "irisControlsBg",
        "label": "Background",
        "desc": "Ryoku-style backing behind the face; none sits bare",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "none",
            "card",
            "glass"
        ]
    },
    {
        "tab": "irisControls",
        "group": "SIZE & SHAPE",
        "key": "irisControlsRadius",
        "label": "Corner radius",
        "desc": "Rounds the backing (and the iNiR plate); 0 is square",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 120.0,
        "unit": "px"
    },
    {
        "tab": "irisControls",
        "group": "SIZE & SHAPE",
        "key": "irisControlsScale",
        "label": "Size",
        "desc": "Scales the face; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "irisControls",
        "group": "SIZE & SHAPE",
        "key": "irisControlsOpacity",
        "label": "Opacity",
        "desc": "Fades the face while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "irisControls",
        "group": "PLACEMENT",
        "key": "irisControlsAnchor",
        "label": "Anchor",
        "desc": "Where the face sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "irisControls",
        "group": "PLACEMENT",
        "key": "irisControlsX",
        "label": "X",
        "desc": "Distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisControlsAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisControls",
        "group": "PLACEMENT",
        "key": "irisControlsY",
        "label": "Y",
        "desc": "Distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisControlsAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisControls",
        "group": "PLACEMENT",
        "key": "irisControlsLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging this face on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "irisMonth",
        "group": "WIDGET",
        "key": "irisMonthEnabled",
        "label": "Enabled",
        "desc": "Shows this face; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "irisMonth",
        "group": "WIDGET",
        "key": "irisMonthStyle",
        "label": "Style",
        "desc": "iNiR draws the face upstream; Ryoku is the paper skin",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "inir",
            "ryoku"
        ]
    },
    {
        "tab": "irisMonth",
        "group": "WIDGET",
        "key": "irisMonthSize",
        "label": "Size preset",
        "desc": "The face's own iRiS layout size",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "small",
            "medium",
            "large"
        ]
    },
    {
        "tab": "irisMonth",
        "group": "SIZE & SHAPE",
        "key": "irisMonthBg",
        "label": "Background",
        "desc": "Ryoku-style backing behind the face; none sits bare",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "none",
            "card",
            "glass"
        ]
    },
    {
        "tab": "irisMonth",
        "group": "SIZE & SHAPE",
        "key": "irisMonthRadius",
        "label": "Corner radius",
        "desc": "Rounds the backing (and the iNiR plate); 0 is square",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 120.0,
        "unit": "px"
    },
    {
        "tab": "irisMonth",
        "group": "SIZE & SHAPE",
        "key": "irisMonthScale",
        "label": "Size",
        "desc": "Scales the face; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "irisMonth",
        "group": "SIZE & SHAPE",
        "key": "irisMonthOpacity",
        "label": "Opacity",
        "desc": "Fades the face while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "irisMonth",
        "group": "PLACEMENT",
        "key": "irisMonthAnchor",
        "label": "Anchor",
        "desc": "Where the face sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "irisMonth",
        "group": "PLACEMENT",
        "key": "irisMonthX",
        "label": "X",
        "desc": "Distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisMonthAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisMonth",
        "group": "PLACEMENT",
        "key": "irisMonthY",
        "label": "Y",
        "desc": "Distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisMonthAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisMonth",
        "group": "PLACEMENT",
        "key": "irisMonthLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging this face on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "irisAgenda",
        "group": "WIDGET",
        "key": "irisAgendaEnabled",
        "label": "Enabled",
        "desc": "Shows this face; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "irisAgenda",
        "group": "WIDGET",
        "key": "irisAgendaStyle",
        "label": "Style",
        "desc": "iNiR draws the face upstream; Ryoku is the paper skin",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "inir",
            "ryoku"
        ]
    },
    {
        "tab": "irisAgenda",
        "group": "WIDGET",
        "key": "irisAgendaSize",
        "label": "Size preset",
        "desc": "The face's own iRiS layout size",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "small",
            "medium",
            "large"
        ]
    },
    {
        "tab": "irisAgenda",
        "group": "SIZE & SHAPE",
        "key": "irisAgendaBg",
        "label": "Background",
        "desc": "Ryoku-style backing behind the face; none sits bare",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "none",
            "card",
            "glass"
        ]
    },
    {
        "tab": "irisAgenda",
        "group": "SIZE & SHAPE",
        "key": "irisAgendaRadius",
        "label": "Corner radius",
        "desc": "Rounds the backing (and the iNiR plate); 0 is square",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 120.0,
        "unit": "px"
    },
    {
        "tab": "irisAgenda",
        "group": "SIZE & SHAPE",
        "key": "irisAgendaScale",
        "label": "Size",
        "desc": "Scales the face; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "irisAgenda",
        "group": "SIZE & SHAPE",
        "key": "irisAgendaOpacity",
        "label": "Opacity",
        "desc": "Fades the face while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "irisAgenda",
        "group": "PLACEMENT",
        "key": "irisAgendaAnchor",
        "label": "Anchor",
        "desc": "Where the face sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "irisAgenda",
        "group": "PLACEMENT",
        "key": "irisAgendaX",
        "label": "X",
        "desc": "Distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisAgendaAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisAgenda",
        "group": "PLACEMENT",
        "key": "irisAgendaY",
        "label": "Y",
        "desc": "Distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisAgendaAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisAgenda",
        "group": "PLACEMENT",
        "key": "irisAgendaLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging this face on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "irisTodo",
        "group": "WIDGET",
        "key": "irisTodoEnabled",
        "label": "Enabled",
        "desc": "Shows this face; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "irisTodo",
        "group": "WIDGET",
        "key": "irisTodoStyle",
        "label": "Style",
        "desc": "iNiR draws the face upstream; Ryoku is the paper skin",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "inir",
            "ryoku"
        ]
    },
    {
        "tab": "irisTodo",
        "group": "WIDGET",
        "key": "irisTodoSize",
        "label": "Size preset",
        "desc": "The face's own iRiS layout size",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "small",
            "medium",
            "large"
        ]
    },
    {
        "tab": "irisTodo",
        "group": "SIZE & SHAPE",
        "key": "irisTodoBg",
        "label": "Background",
        "desc": "Ryoku-style backing behind the face; none sits bare",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "none",
            "card",
            "glass"
        ]
    },
    {
        "tab": "irisTodo",
        "group": "SIZE & SHAPE",
        "key": "irisTodoRadius",
        "label": "Corner radius",
        "desc": "Rounds the backing (and the iNiR plate); 0 is square",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 120.0,
        "unit": "px"
    },
    {
        "tab": "irisTodo",
        "group": "SIZE & SHAPE",
        "key": "irisTodoScale",
        "label": "Size",
        "desc": "Scales the face; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "irisTodo",
        "group": "SIZE & SHAPE",
        "key": "irisTodoOpacity",
        "label": "Opacity",
        "desc": "Fades the face while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "irisTodo",
        "group": "PLACEMENT",
        "key": "irisTodoAnchor",
        "label": "Anchor",
        "desc": "Where the face sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "irisTodo",
        "group": "PLACEMENT",
        "key": "irisTodoX",
        "label": "X",
        "desc": "Distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisTodoAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisTodo",
        "group": "PLACEMENT",
        "key": "irisTodoY",
        "label": "Y",
        "desc": "Distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisTodoAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisTodo",
        "group": "PLACEMENT",
        "key": "irisTodoLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging this face on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "irisNotes",
        "group": "WIDGET",
        "key": "irisNotesEnabled",
        "label": "Enabled",
        "desc": "Shows this face; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "irisNotes",
        "group": "WIDGET",
        "key": "irisNotesStyle",
        "label": "Style",
        "desc": "iNiR draws the face upstream; Ryoku is the paper skin",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "inir",
            "ryoku"
        ]
    },
    {
        "tab": "irisNotes",
        "group": "WIDGET",
        "key": "irisNotesSize",
        "label": "Size preset",
        "desc": "The face's own iRiS layout size",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "small",
            "medium",
            "large"
        ]
    },
    {
        "tab": "irisNotes",
        "group": "SIZE & SHAPE",
        "key": "irisNotesBg",
        "label": "Background",
        "desc": "Ryoku-style backing behind the face; none sits bare",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "none",
            "card",
            "glass"
        ]
    },
    {
        "tab": "irisNotes",
        "group": "SIZE & SHAPE",
        "key": "irisNotesRadius",
        "label": "Corner radius",
        "desc": "Rounds the backing (and the iNiR plate); 0 is square",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 120.0,
        "unit": "px"
    },
    {
        "tab": "irisNotes",
        "group": "SIZE & SHAPE",
        "key": "irisNotesScale",
        "label": "Size",
        "desc": "Scales the face; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "irisNotes",
        "group": "SIZE & SHAPE",
        "key": "irisNotesOpacity",
        "label": "Opacity",
        "desc": "Fades the face while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "irisNotes",
        "group": "PLACEMENT",
        "key": "irisNotesAnchor",
        "label": "Anchor",
        "desc": "Where the face sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "irisNotes",
        "group": "PLACEMENT",
        "key": "irisNotesX",
        "label": "X",
        "desc": "Distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisNotesAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisNotes",
        "group": "PLACEMENT",
        "key": "irisNotesY",
        "label": "Y",
        "desc": "Distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisNotesAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisNotes",
        "group": "PLACEMENT",
        "key": "irisNotesLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging this face on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "irisTimers",
        "group": "WIDGET",
        "key": "irisTimersEnabled",
        "label": "Enabled",
        "desc": "Shows this face; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "irisTimers",
        "group": "WIDGET",
        "key": "irisTimersStyle",
        "label": "Style",
        "desc": "iNiR draws the face upstream; Ryoku is the paper skin",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "inir",
            "ryoku"
        ]
    },
    {
        "tab": "irisTimers",
        "group": "WIDGET",
        "key": "irisTimersSize",
        "label": "Size preset",
        "desc": "The face's own iRiS layout size",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "small",
            "medium"
        ]
    },
    {
        "tab": "irisTimers",
        "group": "SIZE & SHAPE",
        "key": "irisTimersBg",
        "label": "Background",
        "desc": "Ryoku-style backing behind the face; none sits bare",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "none",
            "card",
            "glass"
        ]
    },
    {
        "tab": "irisTimers",
        "group": "SIZE & SHAPE",
        "key": "irisTimersRadius",
        "label": "Corner radius",
        "desc": "Rounds the backing (and the iNiR plate); 0 is square",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 120.0,
        "unit": "px"
    },
    {
        "tab": "irisTimers",
        "group": "SIZE & SHAPE",
        "key": "irisTimersScale",
        "label": "Size",
        "desc": "Scales the face; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "irisTimers",
        "group": "SIZE & SHAPE",
        "key": "irisTimersOpacity",
        "label": "Opacity",
        "desc": "Fades the face while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "irisTimers",
        "group": "PLACEMENT",
        "key": "irisTimersAnchor",
        "label": "Anchor",
        "desc": "Where the face sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "irisTimers",
        "group": "PLACEMENT",
        "key": "irisTimersX",
        "label": "X",
        "desc": "Distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisTimersAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisTimers",
        "group": "PLACEMENT",
        "key": "irisTimersY",
        "label": "Y",
        "desc": "Distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisTimersAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisTimers",
        "group": "PLACEMENT",
        "key": "irisTimersLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging this face on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "irisScreen",
        "group": "WIDGET",
        "key": "irisScreenEnabled",
        "label": "Enabled",
        "desc": "Shows this face; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "irisScreen",
        "group": "WIDGET",
        "key": "irisScreenStyle",
        "label": "Style",
        "desc": "iNiR draws the face upstream; Ryoku is the paper skin",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "inir",
            "ryoku"
        ]
    },
    {
        "tab": "irisScreen",
        "group": "WIDGET",
        "key": "irisScreenSize",
        "label": "Size preset",
        "desc": "The face's own iRiS layout size",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "small",
            "medium",
            "large"
        ]
    },
    {
        "tab": "irisScreen",
        "group": "SIZE & SHAPE",
        "key": "irisScreenBg",
        "label": "Background",
        "desc": "Ryoku-style backing behind the face; none sits bare",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "none",
            "card",
            "glass"
        ]
    },
    {
        "tab": "irisScreen",
        "group": "SIZE & SHAPE",
        "key": "irisScreenRadius",
        "label": "Corner radius",
        "desc": "Rounds the backing (and the iNiR plate); 0 is square",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 120.0,
        "unit": "px"
    },
    {
        "tab": "irisScreen",
        "group": "SIZE & SHAPE",
        "key": "irisScreenScale",
        "label": "Size",
        "desc": "Scales the face; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "irisScreen",
        "group": "SIZE & SHAPE",
        "key": "irisScreenOpacity",
        "label": "Opacity",
        "desc": "Fades the face while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "irisScreen",
        "group": "PLACEMENT",
        "key": "irisScreenAnchor",
        "label": "Anchor",
        "desc": "Where the face sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "irisScreen",
        "group": "PLACEMENT",
        "key": "irisScreenX",
        "label": "X",
        "desc": "Distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisScreenAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisScreen",
        "group": "PLACEMENT",
        "key": "irisScreenY",
        "label": "Y",
        "desc": "Distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisScreenAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisScreen",
        "group": "PLACEMENT",
        "key": "irisScreenLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging this face on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "irisVitals",
        "group": "WIDGET",
        "key": "irisVitalsEnabled",
        "label": "Enabled",
        "desc": "Shows this face; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "irisVitals",
        "group": "WIDGET",
        "key": "irisVitalsStyle",
        "label": "Style",
        "desc": "iNiR draws the face upstream; Ryoku is the paper skin",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "inir",
            "ryoku"
        ]
    },
    {
        "tab": "irisVitals",
        "group": "WIDGET",
        "key": "irisVitalsSize",
        "label": "Size preset",
        "desc": "The face's own iRiS layout size",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "small",
            "medium",
            "large"
        ]
    },
    {
        "tab": "irisVitals",
        "group": "SIZE & SHAPE",
        "key": "irisVitalsBg",
        "label": "Background",
        "desc": "Ryoku-style backing behind the face; none sits bare",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "none",
            "card",
            "glass"
        ]
    },
    {
        "tab": "irisVitals",
        "group": "SIZE & SHAPE",
        "key": "irisVitalsRadius",
        "label": "Corner radius",
        "desc": "Rounds the backing (and the iNiR plate); 0 is square",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 120.0,
        "unit": "px"
    },
    {
        "tab": "irisVitals",
        "group": "SIZE & SHAPE",
        "key": "irisVitalsScale",
        "label": "Size",
        "desc": "Scales the face; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "irisVitals",
        "group": "SIZE & SHAPE",
        "key": "irisVitalsOpacity",
        "label": "Opacity",
        "desc": "Fades the face while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "irisVitals",
        "group": "PLACEMENT",
        "key": "irisVitalsAnchor",
        "label": "Anchor",
        "desc": "Where the face sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "irisVitals",
        "group": "PLACEMENT",
        "key": "irisVitalsX",
        "label": "X",
        "desc": "Distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisVitalsAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisVitals",
        "group": "PLACEMENT",
        "key": "irisVitalsY",
        "label": "Y",
        "desc": "Distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisVitalsAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisVitals",
        "group": "PLACEMENT",
        "key": "irisVitalsLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging this face on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "irisBattery",
        "group": "WIDGET",
        "key": "irisBatteryEnabled",
        "label": "Enabled",
        "desc": "Shows this face; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "irisBattery",
        "group": "WIDGET",
        "key": "irisBatteryStyle",
        "label": "Style",
        "desc": "iNiR draws the face upstream; Ryoku is the paper skin",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "inir",
            "ryoku"
        ]
    },
    {
        "tab": "irisBattery",
        "group": "WIDGET",
        "key": "irisBatterySize",
        "label": "Size preset",
        "desc": "The face's own iRiS layout size",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "small",
            "medium"
        ]
    },
    {
        "tab": "irisBattery",
        "group": "SIZE & SHAPE",
        "key": "irisBatteryBg",
        "label": "Background",
        "desc": "Ryoku-style backing behind the face; none sits bare",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "none",
            "card",
            "glass"
        ]
    },
    {
        "tab": "irisBattery",
        "group": "SIZE & SHAPE",
        "key": "irisBatteryRadius",
        "label": "Corner radius",
        "desc": "Rounds the backing (and the iNiR plate); 0 is square",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 120.0,
        "unit": "px"
    },
    {
        "tab": "irisBattery",
        "group": "SIZE & SHAPE",
        "key": "irisBatteryScale",
        "label": "Size",
        "desc": "Scales the face; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "irisBattery",
        "group": "SIZE & SHAPE",
        "key": "irisBatteryOpacity",
        "label": "Opacity",
        "desc": "Fades the face while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "irisBattery",
        "group": "PLACEMENT",
        "key": "irisBatteryAnchor",
        "label": "Anchor",
        "desc": "Where the face sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "irisBattery",
        "group": "PLACEMENT",
        "key": "irisBatteryX",
        "label": "X",
        "desc": "Distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisBatteryAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisBattery",
        "group": "PLACEMENT",
        "key": "irisBatteryY",
        "label": "Y",
        "desc": "Distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisBatteryAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisBattery",
        "group": "PLACEMENT",
        "key": "irisBatteryLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging this face on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "irisWorld",
        "group": "WIDGET",
        "key": "irisWorldEnabled",
        "label": "Enabled",
        "desc": "Shows this face; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "irisWorld",
        "group": "WIDGET",
        "key": "irisWorldStyle",
        "label": "Style",
        "desc": "iNiR draws the face upstream; Ryoku is the paper skin",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "inir",
            "ryoku"
        ]
    },
    {
        "tab": "irisWorld",
        "group": "WIDGET",
        "key": "irisWorldSize",
        "label": "Size preset",
        "desc": "The face's own iRiS layout size",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "small",
            "medium",
            "large"
        ]
    },
    {
        "tab": "irisWorld",
        "group": "SIZE & SHAPE",
        "key": "irisWorldBg",
        "label": "Background",
        "desc": "Ryoku-style backing behind the face; none sits bare",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "none",
            "card",
            "glass"
        ]
    },
    {
        "tab": "irisWorld",
        "group": "SIZE & SHAPE",
        "key": "irisWorldRadius",
        "label": "Corner radius",
        "desc": "Rounds the backing (and the iNiR plate); 0 is square",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 120.0,
        "unit": "px"
    },
    {
        "tab": "irisWorld",
        "group": "SIZE & SHAPE",
        "key": "irisWorldScale",
        "label": "Size",
        "desc": "Scales the face; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "irisWorld",
        "group": "SIZE & SHAPE",
        "key": "irisWorldOpacity",
        "label": "Opacity",
        "desc": "Fades the face while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "irisWorld",
        "group": "PLACEMENT",
        "key": "irisWorldAnchor",
        "label": "Anchor",
        "desc": "Where the face sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "irisWorld",
        "group": "PLACEMENT",
        "key": "irisWorldX",
        "label": "X",
        "desc": "Distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisWorldAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisWorld",
        "group": "PLACEMENT",
        "key": "irisWorldY",
        "label": "Y",
        "desc": "Distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisWorldAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisWorld",
        "group": "PLACEMENT",
        "key": "irisWorldLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging this face on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "irisDate",
        "group": "WIDGET",
        "key": "irisDateEnabled",
        "label": "Enabled",
        "desc": "Shows this face; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "irisDate",
        "group": "WIDGET",
        "key": "irisDateStyle",
        "label": "Style",
        "desc": "iNiR draws the face upstream; Ryoku is the paper skin",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "inir",
            "ryoku"
        ]
    },
    {
        "tab": "irisDate",
        "group": "SIZE & SHAPE",
        "key": "irisDateBg",
        "label": "Background",
        "desc": "Ryoku-style backing behind the face; none sits bare",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "none",
            "card",
            "glass"
        ]
    },
    {
        "tab": "irisDate",
        "group": "SIZE & SHAPE",
        "key": "irisDateRadius",
        "label": "Corner radius",
        "desc": "Rounds the backing (and the iNiR plate); 0 is square",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 120.0,
        "unit": "px"
    },
    {
        "tab": "irisDate",
        "group": "SIZE & SHAPE",
        "key": "irisDateScale",
        "label": "Size",
        "desc": "Scales the face; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "irisDate",
        "group": "SIZE & SHAPE",
        "key": "irisDateOpacity",
        "label": "Opacity",
        "desc": "Fades the face while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "irisDate",
        "group": "PLACEMENT",
        "key": "irisDateAnchor",
        "label": "Anchor",
        "desc": "Where the face sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "irisDate",
        "group": "PLACEMENT",
        "key": "irisDateX",
        "label": "X",
        "desc": "Distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisDateAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisDate",
        "group": "PLACEMENT",
        "key": "irisDateY",
        "label": "Y",
        "desc": "Distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisDateAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisDate",
        "group": "PLACEMENT",
        "key": "irisDateLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging this face on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "irisProfile",
        "group": "WIDGET",
        "key": "irisProfileEnabled",
        "label": "Enabled",
        "desc": "Shows this face; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "irisProfile",
        "group": "WIDGET",
        "key": "irisProfileStyle",
        "label": "Style",
        "desc": "iNiR draws the face upstream; Ryoku is the paper skin",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "inir",
            "ryoku"
        ]
    },
    {
        "tab": "irisProfile",
        "group": "WIDGET",
        "key": "irisProfileSize",
        "label": "Size preset",
        "desc": "The face's own iRiS layout size",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "small",
            "medium"
        ]
    },
    {
        "tab": "irisProfile",
        "group": "SIZE & SHAPE",
        "key": "irisProfileBg",
        "label": "Background",
        "desc": "Ryoku-style backing behind the face; none sits bare",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "none",
            "card",
            "glass"
        ]
    },
    {
        "tab": "irisProfile",
        "group": "SIZE & SHAPE",
        "key": "irisProfileRadius",
        "label": "Corner radius",
        "desc": "Rounds the backing (and the iNiR plate); 0 is square",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 120.0,
        "unit": "px"
    },
    {
        "tab": "irisProfile",
        "group": "SIZE & SHAPE",
        "key": "irisProfileScale",
        "label": "Size",
        "desc": "Scales the face; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "irisProfile",
        "group": "SIZE & SHAPE",
        "key": "irisProfileOpacity",
        "label": "Opacity",
        "desc": "Fades the face while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "irisProfile",
        "group": "PLACEMENT",
        "key": "irisProfileAnchor",
        "label": "Anchor",
        "desc": "Where the face sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "irisProfile",
        "group": "PLACEMENT",
        "key": "irisProfileX",
        "label": "X",
        "desc": "Distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisProfileAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisProfile",
        "group": "PLACEMENT",
        "key": "irisProfileY",
        "label": "Y",
        "desc": "Distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisProfileAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisProfile",
        "group": "PLACEMENT",
        "key": "irisProfileLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging this face on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "irisUptime",
        "group": "WIDGET",
        "key": "irisUptimeEnabled",
        "label": "Enabled",
        "desc": "Shows this face; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "irisUptime",
        "group": "WIDGET",
        "key": "irisUptimeStyle",
        "label": "Style",
        "desc": "iNiR draws the face upstream; Ryoku is the paper skin",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "inir",
            "ryoku"
        ]
    },
    {
        "tab": "irisUptime",
        "group": "SIZE & SHAPE",
        "key": "irisUptimeBg",
        "label": "Background",
        "desc": "Ryoku-style backing behind the face; none sits bare",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "none",
            "card",
            "glass"
        ]
    },
    {
        "tab": "irisUptime",
        "group": "SIZE & SHAPE",
        "key": "irisUptimeRadius",
        "label": "Corner radius",
        "desc": "Rounds the backing (and the iNiR plate); 0 is square",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 120.0,
        "unit": "px"
    },
    {
        "tab": "irisUptime",
        "group": "SIZE & SHAPE",
        "key": "irisUptimeScale",
        "label": "Size",
        "desc": "Scales the face; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "irisUptime",
        "group": "SIZE & SHAPE",
        "key": "irisUptimeOpacity",
        "label": "Opacity",
        "desc": "Fades the face while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "irisUptime",
        "group": "PLACEMENT",
        "key": "irisUptimeAnchor",
        "label": "Anchor",
        "desc": "Where the face sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "irisUptime",
        "group": "PLACEMENT",
        "key": "irisUptimeX",
        "label": "X",
        "desc": "Distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisUptimeAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisUptime",
        "group": "PLACEMENT",
        "key": "irisUptimeY",
        "label": "Y",
        "desc": "Distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisUptimeAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisUptime",
        "group": "PLACEMENT",
        "key": "irisUptimeLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging this face on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "irisNews",
        "group": "WIDGET",
        "key": "irisNewsEnabled",
        "label": "Enabled",
        "desc": "Shows this face; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "irisNews",
        "group": "WIDGET",
        "key": "irisNewsStyle",
        "label": "Style",
        "desc": "iNiR draws the face upstream; Ryoku is the paper skin",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "inir",
            "ryoku"
        ]
    },
    {
        "tab": "irisNews",
        "group": "WIDGET",
        "key": "irisNewsSize",
        "label": "Size preset",
        "desc": "The face's own iRiS layout size",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "small",
            "medium",
            "large"
        ]
    },
    {
        "tab": "irisNews",
        "group": "SIZE & SHAPE",
        "key": "irisNewsBg",
        "label": "Background",
        "desc": "Ryoku-style backing behind the face; none sits bare",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "none",
            "card",
            "glass"
        ]
    },
    {
        "tab": "irisNews",
        "group": "SIZE & SHAPE",
        "key": "irisNewsRadius",
        "label": "Corner radius",
        "desc": "Rounds the backing (and the iNiR plate); 0 is square",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 120.0,
        "unit": "px"
    },
    {
        "tab": "irisNews",
        "group": "SIZE & SHAPE",
        "key": "irisNewsScale",
        "label": "Size",
        "desc": "Scales the face; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "irisNews",
        "group": "SIZE & SHAPE",
        "key": "irisNewsOpacity",
        "label": "Opacity",
        "desc": "Fades the face while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "irisNews",
        "group": "PLACEMENT",
        "key": "irisNewsAnchor",
        "label": "Anchor",
        "desc": "Where the face sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "irisNews",
        "group": "PLACEMENT",
        "key": "irisNewsX",
        "label": "X",
        "desc": "Distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisNewsAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisNews",
        "group": "PLACEMENT",
        "key": "irisNewsY",
        "label": "Y",
        "desc": "Distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisNewsAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisNews",
        "group": "PLACEMENT",
        "key": "irisNewsLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging this face on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "irisCustomImage",
        "group": "WIDGET",
        "key": "irisCustomImageEnabled",
        "label": "Enabled",
        "desc": "Shows this widget; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "irisCustomImage",
        "group": "WIDGET",
        "key": "irisCustomImageStyle",
        "label": "Style",
        "desc": "iNiR draws it upstream; Ryoku wraps it in the paper backing",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "inir",
            "ryoku"
        ]
    },
    {
        "tab": "irisCustomImage",
        "group": "SIZE & SHAPE",
        "key": "irisCustomImageBg",
        "label": "Background",
        "desc": "Ryoku-style backing behind the widget; none sits bare",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "none",
            "card",
            "glass"
        ]
    },
    {
        "tab": "irisCustomImage",
        "group": "SIZE & SHAPE",
        "key": "irisCustomImageRadius",
        "label": "Corner radius",
        "desc": "Rounds the backing; 0 is square",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 120.0,
        "unit": "px"
    },
    {
        "tab": "irisCustomImage",
        "group": "SIZE & SHAPE",
        "key": "irisCustomImageScale",
        "label": "Size",
        "desc": "Scales the widget; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "irisCustomImage",
        "group": "SIZE & SHAPE",
        "key": "irisCustomImageOpacity",
        "label": "Opacity",
        "desc": "Fades the widget while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "irisCustomImage",
        "group": "PLACEMENT",
        "key": "irisCustomImageAnchor",
        "label": "Anchor",
        "desc": "Where it sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "irisCustomImage",
        "group": "PLACEMENT",
        "key": "irisCustomImageX",
        "label": "X",
        "desc": "Distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisCustomImageAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisCustomImage",
        "group": "PLACEMENT",
        "key": "irisCustomImageY",
        "label": "Y",
        "desc": "Distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisCustomImageAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisCustomImage",
        "group": "PLACEMENT",
        "key": "irisCustomImageLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging it on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "irisEditorial",
        "group": "WIDGET",
        "key": "irisEditorialEnabled",
        "label": "Enabled",
        "desc": "Shows this widget; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "irisEditorial",
        "group": "WIDGET",
        "key": "irisEditorialStyle",
        "label": "Style",
        "desc": "iNiR draws it upstream; Ryoku wraps it in the paper backing",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "inir",
            "ryoku"
        ]
    },
    {
        "tab": "irisEditorial",
        "group": "SIZE & SHAPE",
        "key": "irisEditorialBg",
        "label": "Background",
        "desc": "Ryoku-style backing behind the widget; none sits bare",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "none",
            "card",
            "glass"
        ]
    },
    {
        "tab": "irisEditorial",
        "group": "SIZE & SHAPE",
        "key": "irisEditorialRadius",
        "label": "Corner radius",
        "desc": "Rounds the backing; 0 is square",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 120.0,
        "unit": "px"
    },
    {
        "tab": "irisEditorial",
        "group": "SIZE & SHAPE",
        "key": "irisEditorialScale",
        "label": "Size",
        "desc": "Scales the widget; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "irisEditorial",
        "group": "SIZE & SHAPE",
        "key": "irisEditorialOpacity",
        "label": "Opacity",
        "desc": "Fades the widget while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "irisEditorial",
        "group": "PLACEMENT",
        "key": "irisEditorialAnchor",
        "label": "Anchor",
        "desc": "Where it sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "irisEditorial",
        "group": "PLACEMENT",
        "key": "irisEditorialX",
        "label": "X",
        "desc": "Distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisEditorialAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisEditorial",
        "group": "PLACEMENT",
        "key": "irisEditorialY",
        "label": "Y",
        "desc": "Distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisEditorialAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisEditorial",
        "group": "PLACEMENT",
        "key": "irisEditorialLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging it on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "irisConverter",
        "group": "WIDGET",
        "key": "irisConverterEnabled",
        "label": "Enabled",
        "desc": "Shows this widget; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "irisConverter",
        "group": "WIDGET",
        "key": "irisConverterStyle",
        "label": "Style",
        "desc": "iNiR draws it upstream; Ryoku wraps it in the paper backing",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "inir",
            "ryoku"
        ]
    },
    {
        "tab": "irisConverter",
        "group": "SIZE & SHAPE",
        "key": "irisConverterBg",
        "label": "Background",
        "desc": "Ryoku-style backing behind the widget; none sits bare",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "none",
            "card",
            "glass"
        ]
    },
    {
        "tab": "irisConverter",
        "group": "SIZE & SHAPE",
        "key": "irisConverterRadius",
        "label": "Corner radius",
        "desc": "Rounds the backing; 0 is square",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 120.0,
        "unit": "px"
    },
    {
        "tab": "irisConverter",
        "group": "SIZE & SHAPE",
        "key": "irisConverterScale",
        "label": "Size",
        "desc": "Scales the widget; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "irisConverter",
        "group": "SIZE & SHAPE",
        "key": "irisConverterOpacity",
        "label": "Opacity",
        "desc": "Fades the widget while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "irisConverter",
        "group": "PLACEMENT",
        "key": "irisConverterAnchor",
        "label": "Anchor",
        "desc": "Where it sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "irisConverter",
        "group": "PLACEMENT",
        "key": "irisConverterX",
        "label": "X",
        "desc": "Distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisConverterAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisConverter",
        "group": "PLACEMENT",
        "key": "irisConverterY",
        "label": "Y",
        "desc": "Distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisConverterAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisConverter",
        "group": "PLACEMENT",
        "key": "irisConverterLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging it on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "irisJp",
        "group": "WIDGET",
        "key": "irisJpEnabled",
        "label": "Enabled",
        "desc": "Shows this widget; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "irisJp",
        "group": "WIDGET",
        "key": "irisJpStyle",
        "label": "Style",
        "desc": "iNiR draws it upstream; Ryoku wraps it in the paper backing",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "inir",
            "ryoku"
        ]
    },
    {
        "tab": "irisJp",
        "group": "SIZE & SHAPE",
        "key": "irisJpBg",
        "label": "Background",
        "desc": "Ryoku-style backing behind the widget; none sits bare",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "none",
            "card",
            "glass"
        ]
    },
    {
        "tab": "irisJp",
        "group": "SIZE & SHAPE",
        "key": "irisJpRadius",
        "label": "Corner radius",
        "desc": "Rounds the backing; 0 is square",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 120.0,
        "unit": "px"
    },
    {
        "tab": "irisJp",
        "group": "SIZE & SHAPE",
        "key": "irisJpScale",
        "label": "Size",
        "desc": "Scales the widget; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "irisJp",
        "group": "SIZE & SHAPE",
        "key": "irisJpOpacity",
        "label": "Opacity",
        "desc": "Fades the widget while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "irisJp",
        "group": "PLACEMENT",
        "key": "irisJpAnchor",
        "label": "Anchor",
        "desc": "Where it sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "irisJp",
        "group": "PLACEMENT",
        "key": "irisJpX",
        "label": "X",
        "desc": "Distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisJpAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisJp",
        "group": "PLACEMENT",
        "key": "irisJpY",
        "label": "Y",
        "desc": "Distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisJpAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisJp",
        "group": "PLACEMENT",
        "key": "irisJpLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging it on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    },
    {
        "tab": "irisVisualizer",
        "group": "WIDGET",
        "key": "irisVisualizerEnabled",
        "label": "Enabled",
        "desc": "Shows this widget; your settings are kept while off",
        "ctl": "sw",
        "src": "widgets.json"
    },
    {
        "tab": "irisVisualizer",
        "group": "WIDGET",
        "key": "irisVisualizerStyle",
        "label": "Style",
        "desc": "iNiR draws it upstream; Ryoku wraps it in the paper backing",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "inir",
            "ryoku"
        ]
    },
    {
        "tab": "irisVisualizer",
        "group": "SIZE & SHAPE",
        "key": "irisVisualizerBg",
        "label": "Background",
        "desc": "Ryoku-style backing behind the widget; none sits bare",
        "ctl": "seg",
        "src": "widgets.json",
        "opts": [
            "none",
            "card",
            "glass"
        ]
    },
    {
        "tab": "irisVisualizer",
        "group": "SIZE & SHAPE",
        "key": "irisVisualizerRadius",
        "label": "Corner radius",
        "desc": "Rounds the backing; 0 is square",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 120.0,
        "unit": "px"
    },
    {
        "tab": "irisVisualizer",
        "group": "SIZE & SHAPE",
        "key": "irisVisualizerScale",
        "label": "Size",
        "desc": "Scales the widget; 100% is its designed size",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.5,
        "hi": 2.5
    },
    {
        "tab": "irisVisualizer",
        "group": "SIZE & SHAPE",
        "key": "irisVisualizerOpacity",
        "label": "Opacity",
        "desc": "Fades the widget while keeping it readable",
        "ctl": "slid",
        "src": "widgets.json",
        "lo": 0.2,
        "hi": 1.0,
        "unit": "%",
        "pct": true
    },
    {
        "tab": "irisVisualizer",
        "group": "PLACEMENT",
        "key": "irisVisualizerAnchor",
        "label": "Anchor",
        "desc": "Where it sits; Auto finds a calm spot, Free X/Y",
        "ctl": "pick",
        "src": "widgets.json",
        "opts": [
            "auto",
            "top-left",
            "top",
            "top-right",
            "left",
            "center",
            "right",
            "bottom-left",
            "bottom",
            "bottom-right",
            "free"
        ]
    },
    {
        "tab": "irisVisualizer",
        "group": "PLACEMENT",
        "key": "irisVisualizerX",
        "label": "X",
        "desc": "Distance from the left edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisVisualizerAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisVisualizer",
        "group": "PLACEMENT",
        "key": "irisVisualizerY",
        "label": "Y",
        "desc": "Distance from the top edge, in pixels",
        "ctl": "step",
        "src": "widgets.json",
        "lo": 0.0,
        "hi": 5000.0,
        "unit": "px",
        "when": {
            "irisVisualizerAnchor": [
                "free"
            ]
        }
    },
    {
        "tab": "irisVisualizer",
        "group": "PLACEMENT",
        "key": "irisVisualizerLocked",
        "label": "Lock on desktop",
        "desc": "Blocks dragging it on the desktop",
        "ctl": "sw",
        "src": "widgets.json",
        "adv": true
    }
];
