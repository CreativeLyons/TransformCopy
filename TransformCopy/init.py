# TransformCopy - Nuke Plugin Init
# Automatically loads the correct plugin version based on Nuke major version

import nuke
import os

def load_transformcopy():
    """Load TransformCopy plugin for the current Nuke version."""
    plugin_dir = os.path.dirname(__file__)
    nuke_major = nuke.NUKE_VERSION_MAJOR
    
    # Map Nuke major versions to plugin subdirectories
    version_map = {
        15: "Nuke15",
        16: "Nuke16",
    }
    
    if nuke_major in version_map:
        subfolder = version_map[nuke_major]
        plugin_path = os.path.join(plugin_dir, subfolder)
        
        if os.path.exists(plugin_path):
            nuke.pluginAddPath(plugin_path)
            # Load the plugin explicitly
            try:
                nuke.load("TransformCopy")
            except RuntimeError as e:
                nuke.tprint("TransformCopy: Failed to load plugin - {}".format(str(e)))
        else:
            nuke.tprint("TransformCopy: Plugin folder not found for Nuke {}".format(nuke_major))
    else:
        nuke.tprint("TransformCopy: Nuke {} is not supported (supported: 15, 16)".format(nuke_major))

# Load on init
load_transformcopy()
