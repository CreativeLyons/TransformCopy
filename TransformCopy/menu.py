# TransformCopy - Nuke Plugin Menu
# Adds TransformCopy to the Transform menu

import nuke

# Add to Transform menu
toolbar = nuke.menu("Nodes")
transform_menu = toolbar.findItem("Transform")

if transform_menu:
    transform_menu.addCommand("TransformCopy", "nuke.createNode('TransformCopy')", icon="Transform.png")
else:
    # Fallback: add to main menu if Transform not found
    toolbar.addCommand("Transform/TransformCopy", "nuke.createNode('TransformCopy')", icon="Transform.png")
