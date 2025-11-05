# Generating FlightyClone.xcodeproj

## Context

The FlightyClone project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project from `FlightyClone/project.yml`. The generated `.xcodeproj` is tracked in git to ensure CI compatibility with Xcode 15.4 (project format 76).

## Why Track the Generated Project?

Normally, generated files are not committed to version control. However, we track `FlightyClone.xcodeproj/project.pbxproj` for the following reasons:

1. **CI Compatibility**: Ensures the project file is in format 76 (Xcode 15.4 compatible), not format 77 (Xcode 16)
2. **Consistency**: All developers and CI use the same project format
3. **Quick Setup**: Developers can clone and build immediately without running XcodeGen first

## Generating the Project

### Prerequisites

- macOS with Xcode 15.4 installed
- XcodeGen installed (`brew install xcodegen`)

### Steps

1. **Navigate to the FlightyClone directory:**
   ```bash
   cd FlightyClone
   ```

2. **Ensure Xcode 15.4 is active:**
   ```bash
   sudo xcode-select -s /Applications/Xcode_15.4.app/Contents/Developer
   xcodebuild -version  # Should show "Xcode 15.4"
   ```

3. **Generate the project:**
   ```bash
   xcodegen generate --spec project.yml
   ```

4. **Verify the generated project:**
   ```bash
   ls -la FlightyClone.xcodeproj/
   cat FlightyClone.xcodeproj/project.pbxproj | grep "objectVersion"
   # Should show: objectVersion = 56; (format 76)
   # NOT: objectVersion = 60; (format 77)
   ```

5. **Commit the generated project:**
   ```bash
   cd ..
   git add FlightyClone/FlightyClone.xcodeproj/project.pbxproj
   git commit -m "chore: regenerate Xcode project with format 76 (Xcode 15.4)"
   git push
   ```

## After Generation

Once the project is generated and committed with format 76, the CI will be able to:

1. Read the existing `.xcodeproj` file
2. Or regenerate it (which should produce the same format due to `xcodeVersion: "15.4"` and `lastUpgradeVersion: "1540"` settings)
3. Build successfully without "future project file format" errors

## Troubleshooting

### "objectVersion = 60" (Format 77)

If you see objectVersion 60, you're using Xcode 16. Switch to Xcode 15.4:

```bash
sudo xcode-select -s /Applications/Xcode_15.4.app/Contents/Developer
```

### XcodeGen Generates Format 77 Despite Settings

This can happen if:
- XcodeGen is too new and defaults to the latest format
- The `xcodeVersion` setting is not respected by your XcodeGen version

Solution: Downgrade XcodeGen or use the specific version that respects the xcodeVersion setting.

### CI Still Fails After Committing

1. Verify the committed file is format 76:
   ```bash
   git show HEAD:FlightyClone/FlightyClone.xcodeproj/project.pbxproj | grep objectVersion
   ```

2. Check the CI logs to see if XcodeGen is regenerating the project
3. If CI regenerates, ensure `project.yml` has `lastUpgradeVersion: "1540"`

## Reference

- **Xcode 15.4**: Project format 56 (objectVersion 56)
- **Xcode 16.0**: Project format 60 (objectVersion 60)
- **XcodeGen Docs**: https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md

## Current Configuration

```yaml
# FlightyClone/project.yml
options:
  xcodeVersion: "15.4"        # Target Xcode version
  lastUpgradeVersion: "1540"  # Xcode 15.4 upgrade version
```
