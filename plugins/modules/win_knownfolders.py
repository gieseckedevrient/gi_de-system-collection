#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2020, Giesecke Devrient

DOCUMENTATION = r'''
---
module: win_knownfolders
version_added: "1.3.5"
short_description: Get the location of a known folder
description:
  - Get the location of a known folder independantly from the culture
  - Any windows instance has a quite extensive list of folders that can be accessed by its name. See the full list here
options:
  name:
    description: Names to display known folder path
    type: str
    required: false
    default: all
    choices:
      - all
      - SampleVideos
      - InternetCache
      - AccountPictures
      - SavedGames
      - ComputerFolder
      - ConflictFolder
      - SampleMusic
      - RecordedTVLibrary
      - SearchTemplates
      - SavedPicturesLibrary
      - PhotoAlbums
      - SkyDriveDocuments
      - System
      - Playlists
      - ProgramFiles
      - Videos
      - ProgramFilesCommon
      - Windows
      - ResourceDir
      - StartMenu
      - Cookies
      - UserProfiles
      - SamplePictures
      - ChangeRemovePRograms
      - LocalAppDataLow
      - Startup
      - CommonOEMLinks
      - PublicGameTasks
      - Recent
      - PublicDownloads
      - Games
      - SEARCH_MAPI
      - SavedSearches
      - ProgramFilesX86
      - RoamingAppData
      - Links
      - PublicDesktop
      - CommonStartMenu
      - Templates
      - PublicUserTiles
      - DeviceMetadataStore
      - ProgramData
      - Downloads
      - UserProgramFiles
      - RoamingTiles
      - SkyDrivePictures
      - SamplePlaylists
      - SyncSetupFolder
      - ProgramFilesCommonX86
      - MusicLibrary
      - Programs
      - Ringtones
      - Music
      - UserPinned
      - Contacts
      - SyncResultsFolder
      - AppUpdates
      - NetHood
      - VideosLibrary
      - PublicPictures
      - SkyDriveCameraRoll
      - GameTasks
      - AdminTools
      - PublicLibraries
      - LocalizedResourceDir
      - PublicDocuments
      - SearchHome
      - LocalAppData
      - Screenshots
      - CommonPrograms
      - PublicVideos
      - PublicRingtones
      - SyncManagerFolder
      - Pictures
      - Public
      - Desktop
      - HomeGroupCurrentUser
      - SidebarDefaultParts
      - SearchHistory
      - SEARCH_CSC
      - AppsFolder
      - RoamedTileImages
      - Favorites
      - CommonStartup
      - ProgramFilesX64
      - SystemX86
      - AddNewPrograms
      - UsersFiles
      - Fonts
      - SkyDrive
      - SidebarParts
      - PrintersFolder
      - UsersLibraries
      - DocumentsLibrary
      - ControlPanelFolder
      - History
      - NetworkFolder
      - Profile
      - PicturesLibrary
      - CameraRoll
      - ApplicationShortcuts
      - ProgramFilesCommonX64
      - SavedPictures
      - InternetFolder
      - CommonTemplates
      - SendTo
      - PrintHood
      - RecycleBinFolder
      - QuickLaunch
      - Libraries
      - CDBurning
      - ConnectionsFolder
      - HomeGroup
      - Documents
      - PublicMusic
      - ImplicitAppShortcuts
      - CommonAdminTools
      - OriginalImages
      - UserProgramFilesCommon
author: Giesecke Devrient
'''

EXAMPLES = r'''
- name: Get windows startup folder
  gi_de.system.win_knownfolders:
    name: "CommonStartup"
  register: _found_startup_folder
'''

RETURN = r'''
exist:
  type: bool
  description: if any folder found or not
FolderPaths:
  description: found folderpath
  type: dict
  contains:
    Name:
      description: the name of known folder
      type: str
    Path:
      description: the fullpath
      type: str
'''
