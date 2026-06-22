//////////////////////////////////////////////////////////
// SIEMENS Healthineers AG 2024
//////////////////////////////////////////////////////////

This folder contains C# and python example code for processing the physiological non-image DICOMs of the PhysioLogging feature
NOTE: The provided source code example of the physioExtractor is only meant for demonstration purposes and comes with no warranty!
You are free to modify the code according to your needs.

In case you want to compile the C# code in IDEA, the following steps have to be performed as a preparation:
1.	Load Visual Studio Environment:
	a) Run '_vsvars' inside IDEA 
	or
	b) Open 'Developer Command prompt for VS [version]' via start menu (e.g. 'Developer Command prompt for VS 2022')
2.	Run: pushd %IDEA_BASE%\MrMake
3.	Create Keyfile.snk: sn -k KeyFile.snk
see https://docs.microsoft.com/en-us/dotnet/standard/assembly/create-public-private-key-pair

For further information on the physioExtractor program, please check the description in the ICE Users Guide