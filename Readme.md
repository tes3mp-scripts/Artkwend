This script fixes some of the issues with Arktwend in TES3MP. Only lightly untested.

Artkwend download link: https://sureai.net/games/arktwend/.

Read [this page](https://github.com/tes3mp-scripts/Tutorials/blob/master/ServerSetup.md) on how to set up your server.

Since you are running Artkwend, change your `requiredDataFiles.json` to the following (assuming you are using the English version)
```json
[
    {"Arktwend_English.esm": []}
]
```

After that simply put all the files in this repo into your `server/scripts/custom/Arktwend/` and add `require("custom.Artkwend.main")` to your `server/scripts/customScripts.lua`.

This script makes you respawn in the same cell you died after just 30 seconds. This is done due to the relatively linear nature of Artkwend.