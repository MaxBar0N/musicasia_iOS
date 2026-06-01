import os
from pbxproj import XcodeProject

project = XcodeProject.load('MusicAsia.xcodeproj/project.pbxproj')

files_to_add = [
    'MusicAsia/Sources/Network/APIService.swift',
    'MusicAsia/Sources/Network/NetworkManager.swift',
    'MusicAsia/Sources/Network/API/AuthAPI.swift',
    'MusicAsia/Sources/Network/API/HomeAPI.swift',
    'MusicAsia/Sources/Network/API/SongAPI.swift',
    'MusicAsia/Sources/Network/API/AlbumAPI.swift',
    'MusicAsia/Sources/Network/API/ProfileAPI.swift',
    'MusicAsia/Sources/Network/API/DeviceAPI.swift',
    'MusicAsia/Sources/Network/API/OrderAPI.swift'
]

for file_path in files_to_add:
    if os.path.exists(file_path):
        print(f"Adding {file_path}")
        # Add the file to the project and link it to the MusicAsia target
        project.add_file(file_path, target_name='MusicAsia', force=False)
    else:
        print(f"File not found: {file_path}")

project.save()
print("Done")
