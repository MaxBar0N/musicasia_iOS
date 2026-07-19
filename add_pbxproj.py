import sys

pbx_path = "/Users/max/Desktop/Github/musicasia_iOS/MusicAsia.xcodeproj/project.pbxproj"

with open(pbx_path, "r") as f:
    lines = f.readlines()

file_ref = "112233445566778899AABBCC"
build_file = "AABBCCDDEEFF001122334455"
filename = "IAPManager.swift"

new_lines = []
in_managers_group = False
in_sourcesbuildphase = False

for line in lines:
    new_lines.append(line)
    
    # 1. PBXBuildFile
    if "/* Begin PBXBuildFile section */" in line:
        new_lines.append(f"\t\t{build_file} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref} /* {filename} */; }};\n")
        
    # 2. PBXFileReference
    if "/* Begin PBXFileReference section */" in line:
        new_lines.append(f"\t\t{file_ref} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};\n")
        
    # 3. Managers group
    if "/* Managers */ = {" in line:
        in_managers_group = True
    if in_managers_group and "children = (" in line:
        new_lines.append(f"\t\t\t\t{file_ref} /* {filename} */,\n")
        in_managers_group = False
        
    # 4. PBXSourcesBuildPhase
    if "/* Begin PBXSourcesBuildPhase section */" in line:
        in_sourcesbuildphase = True
    if in_sourcesbuildphase and "files = (" in line:
        new_lines.append(f"\t\t\t\t{build_file} /* {filename} in Sources */,\n")
        in_sourcesbuildphase = False

with open(pbx_path, "w") as f:
    f.writelines(new_lines)
    
print("Added to pbxproj successfully.")