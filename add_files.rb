require 'xcodeproj'

project_path = 'MusicAsia.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'MusicAsia' }

files = [
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

files.each do |file_path|
    file_ref = project.main_group.new_reference(file_path)
    target.add_file_references([file_ref])
end

project.save
puts "Added files successfully."