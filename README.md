## appcast_generator

This package is supposed to generate an Appcast file and add entries via CLI.

Go to the bin folder:
```
dart run appcast_generator.dart create -f appcast.xml -t "Skyle Windows App" -d "App to use the Skyle Eyetracker for Windows made by eyeV GmbH." -l "https://eyev.de/dl/windows/appcast.xml" -language "en"

dart run appcast_generator.dart add -f "test_out_2.xml" -t "Version 1.1" -n "https://eyev.de/dl/windows/notes.md" -u "https://eyev.de/dl/windows/Skyle.msi" -o "windows" -v "1.1" --file <YOUR_EXE_OR_MSI_FILE>
```

## Getting Started


# appcast_generator
