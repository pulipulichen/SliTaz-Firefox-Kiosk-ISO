#!/usr/bin/env python
# The SliTaz IBus 1.4 package supplies the Python 2 ibus module.
import time
import ibus

for attempt in range(30):
    try:
        bus = ibus.Bus()
        config = bus.get_config()
        config.set_value('general', 'preload_engines', ['rime'])
        config.set_value('general', 'use_global_engine', True)
        config.set_value('general/hotkey', 'trigger', ['Control+space'])
        break
    except Exception:
        if attempt == 29:
            raise
        time.sleep(1)
