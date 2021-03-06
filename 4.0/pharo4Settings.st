StartupPreferencesLoader default executeAtomicItems: {	
	
	

    StartupAction 
      name: 'Set the Author' 
      code: [ Author fullName: 'CyrilFerlicot' ] 
      runOnce: true. 
 
    StartupAction 
      name: 'GTSpotter usage data' 
      code: [ (Smalltalk globals includesKey: #GTSpotterEventRecorderSettings) ifTrue: [ #GTSpotterEventRecorderSettings asClass sendUsageData: true ] ] 
      runOnce: true. 
 
    StartupAction 
      name: 'No logo' 
      code: [  PolymorphSystemSettings showDesktopLogo: false ] 
      runOnce: true. 
       
    StartupAction 
      name: 'AdaptTheme' 
      code: [  
          | installThemeBlock currentTheme | 
 
          installThemeBlock := [ | theme | 
            theme := (Time now between: '7:00am' asTime and: '9:00pm' asTime) ifTrue: [ Pharo3DarkTheme ] ifFalse: [ Pharo3Theme ]. 
            theme = currentTheme ifFalse: [ currentTheme := theme. PolymorphSystemSettings uiThemeClass: currentTheme.  UITheme currentSettings fastDragging: true ] ]. 
 
            [ [ installThemeBlock value. 5 minutes asDelay wait ] repeat ]  
              newProcess priority: Processor systemBackgroundPriority;  
              name: 'changeTheme';  
              resume  
        ] 
      runOnce: true. 
     
    StartupAction  
      name: 'Fast dragging'  
      code: [ UITheme currentSettings fastDragging: true ] 
      runOnce: true. 
     
    StartupAction 
      name: 'Exhibits bounds'  
      code: [ HaloMorph showBoundsInHalo: true ]  
      runOnce: true. 
     
    StartupAction  
      name: 'Desktop background image file name'  
      code: [ | files | 
        files := (StartupPreferencesLoader preferencesGeneralFolder / 'SettingRessources' / 'backgrounds') allFiles. 
        PolymorphSystemSettings desktopImageFileName: (files at: (UUIDGenerator default makeSeed \\ files size) + 1) fullName. ]  
      runOnce: false. 
     
    StartupAction  
      name: 'Class Template with Slots'  
      code: [ Slot showSlotClassDefinition: true ] 
      runOnce: true. 
     
    StartupAction 
      name: 'Local Playground cache directory' 
      code: [ GTPlayBook cacheDirectory: (StartupPreferencesLoader preferencesGeneralFolder / 'play-cache') ] 
      runOnce: true. 
     
    StartupAction 
      name: 'Local Playground stash directory' 
      code: [ GTPlayBook stashDirectory: (StartupPreferencesLoader preferencesGeneralFolder / 'play-stash' ) ] 
      runOnce: true. 
     
    StartupAction  
      name: 'Local cache directory'  
      code: [ MCCacheRepository cacheDirectory:  (StartupPreferencesLoader preferencesGeneralFolder / 'package-cache' ) ] 
      runOnce: true. 
     
    StartupAction 
      name: 'Set Monticello infos' 
      code: [ (Smalltalk globals includesKey: #STON) 
        ifTrue: [ | creds file | 
          file := StartupPreferencesLoader preferencesGeneralFolder / 'SettingRessources' / 'Creds'. 
          file exists ifFalse: [ | cred | cred := Dictionary new.  cred at: #username put: (UIManager default textEntry: 'Username'). cred at: #password put: (UIManager default requestPassword: 'Password').  file writeStreamDo: [ :s | s nextPutAll: (STON toStringPretty: cred) ] ]. 
          creds := STON fromString: file contents. 
          MCRepositoryGroup default repositories do: [ :rep | [ rep user: (creds at: #username). rep password: (creds at: #password) ] on: Error do: [  ] ] ] 
      ] 
      runOnce: true. 
     
    StartupAction 
      name: 'Set only dirty in MC' 
      code: [ MCWorkingCopyBrowser order: 4 ] 
      runOnce: true. 
     
    StartupAction 
      name: 'Remove Pharo Repositories to avoid to lose time with Monticello' 
      code: [ MCRepositoryGroup default repositories select: [ :r | (r isKindOf: MCFileBasedRepository) and: [ r location includesSubstring: 'Pharo/Pharo' ] ] thenDo: [ :r | MCRepositoryGroup default removeRepository: r ] ] 
      runOnce: true. 
     
    StartupAction 
      name: 'Generate Accessor automatically' 
      code: [ Object compile: 'doesNotUnderstand: aMessage 
    | exception resumeValue message | 
    message := aMessage selector asString. 
    message last = $: 
      ifTrue: [ self class instVarNames 
          detect: [ :var | var = message allButLast ] 
          ifFound: [ :var |  
            self class 
              compile: 
                (String 
                  streamContents: [ :s |  
                    s 
                      << message; 
                      << '' anObject''; 
                      << String cr; 
                      << Character tab; 
                      << var; 
                      << '' := anObject'' ]) 
              classified: ''accessing''. 
            UIManager default inform: ''Compiled: '' , message , '' into: '' , self printString. 
            ^ aMessage sentTo: self ] ] 
      ifFalse: [ self class instVarNames 
          detect: [ :var | var = message ] 
          ifFound: [ :var |  
            self class 
              compile: 
                (String 
                  streamContents: [ :s |  
                    s 
                      << var; 
                      cr; 
                      << Character tab; 
                      << ''^ ''; 
                      << var ]) 
              classified: ''accessing''. 
            UIManager default inform: ''Compiled: '' , message , '' into: '' , self printString. 
            ^ aMessage sentTo: self ] ]. 
    (exception := MessageNotUnderstood new) 
      message: aMessage; 
      receiver: self. 
    resumeValue := exception signal. 
    ^ exception reachedDefaultHandler 
      ifTrue: [ aMessage sentTo: self ] 
      ifFalse: [ resumeValue ]' ] 
      runOnce: true. 
     
    StartupAction 
      name: 'Set the default github-cache' 
      code: [  
        MCGitHubRepository cacheDirectory: 
          (((OSPlatform current isWindows 
            ifTrue: [ FileLocator C "This is a hack to shorten windows's paths because windows have a max path of 255 characters :(" ] 
            ifFalse: [ StartupPreferencesLoader preferencesGeneralFolder ]) / 'github-cache') 
            ensureCreateDirectory; 
            yourself) 
      ] 
      runOnce: true. 
     
    StartupAction 
      name: 'Add entry to Nautilus package menu to use Komitter' 
      code: [ 
    |remotesCode code| 
    "Workaround for Pharo 5 https://pharo.fogbugz.com/f/cases/18927/Komitter-throws-up-if-it-has-committed-everything" 
    remotesCode := 'remotes 
    | result | 
   
    self packages ifEmpty: [ ^ #() ]. 
   
    result := self packages first remotes. 
    self packages allButFirst do: [ :each | 
      result := result intersection: each remotes ]. 
   
    ^ result collect: [ :each | each koRemote ]'. 
    KomitStagingArea compile: remotesCode. 
    code := 'packagesMenu: aBuilder 
    <nautilusGlobalPackageMenu> 
    | packageNames target | 
    target := aBuilder model. 
    (packageNames := target selectedPackages collect: #name) ifEmpty: [ ^ target ]. 
    (aBuilder item: #''Commit with Komitter...'') 
      action: [ 
        Komitter openAndCommitToMonticelloWorkingCopiesFilteredBy: [ :workingCopy | 
          packageNames includes: workingCopy package name ] ]; 
      order: 1295; 
      help: ''Open a Komitter on the selected package(s)''; 
      icon: Komitter taskbarIcon'. 
    Komitter class compile: code classified: '*_UnpackagedPackage'. 
      ] 
      runOnce: true. 
     
    StartupAction 
      name: 'Add Metacello API' 
      code: [ 
      Metacello compile: 'stHubConf: userName project: projectName 
        self smalltalkhubUser: userName project: projectName. 
        self configuration: projectName' classified: '*_UnpackagedPackage'. 
   
      Metacello compile: 'githubBaseline: userName project: projectName commitish: commitish path: path 
        self githubUser: userName project: projectName commitish: commitish path: path. 
        self baseline: projectName' classified: '*_UnpackagedPackage'. 
   
      Metacello class compile: 'githubUser: userName project: projectName commitish: commitish path: path 
        ^ self new  
          githubUser: userName project: projectName commitish: commitish path: path; 
          baseline: projectName; 
          onWarningLog; 
          load' classified: '*_UnpackagedPackage'. 
   
      Metacello class compile: 'stHubUser: userName project: projectName 
        ^ self new  
          smalltalkhubUser: userName project: projectName; 
          configuration: projectName; 
          onWarningLog; 
  +
          load' classified: '*_UnpackagedPackage'. 
      ] 
      runOnce: true. 
	
			
	StartupAction
		name: 'Idea icons'
		code: [
			Gofer it directory: ((StartupPreferencesLoader preferencesGeneralFolder / 'SettingRessources' / 'ProjectCache' / 'IdeaIcons') fullName); package: 'Polymorph-Icons-Idea';load.
			ThemeIcons current: #IdeaUIThemeIcons asClass new.
			AbstractNautilusUI resetIconCaches
		]
		runOnce: true.
	
	StartupAction
		name: 'Install ston if needed'
		code: [ "This is mostly fos QuickAccess but also because I use a lot of stuff using STON"
			(Smalltalk globals includesKey: #STON) ifFalse: [
				Metacello new
					configuration: 'Ston';
					repository:  (StartupPreferencesLoader preferencesGeneralFolder / 'SettingRessources' / 'ProjectCache' / 'STON' / 'Pharo4' ) fullName;
					load
			]
		]
		runOnce: true.
		
	StartupAction 
		name: 'Close welcolm window' 
		code: [ (SystemWindow allInstances select:  [ :w | w labelString includesSubstring: 'Welcome' ]) do: #delete ]
		runOnce: true.
		
	StartupAction
		name: 'GTSpotter preview'
		code: [ GTSpotter showPreview ]
		runOnce: true.
	
	StartupAction
		name: 'My template'
		code: [ TClassDescription compile: 'classCommentBlank
	| existingComment stream |
	(existingComment := self theNonMetaClass organization classComment) ifNotEmpty: [ ^ existingComment ].
	(stream := (String new: 100) writeStream)
		<<
			''Description
--------------------

One line summary. For example, "I represent a paragraph of text".

Three sentences about my main responsibilities - what I do, what I know.

State my main collaborators and one line about how I interact with them. 

Public API and Key Messages
--------------------

- #
- #
- #

Examples
--------------------

	
 
Internal Representation and Key Implementation Points.
--------------------''.
	self instVarNames
		ifNotEmpty: [ stream
				cr;
				cr;
				nextPutAll: ''    Instance Variables'' ].
	self instVarNames asSortedCollection
		do: [ :each | 
			stream
				cr;
				tab;
				nextPutAll: each;
				nextPut: $:;
				tab;
				tab;
				nextPutAll: ''<Object>'' ].
	^ stream
		cr;
		contents'  ]
		runOnce: true.
	
	StartupAction
		name: 'Short Halt'
		code: [ Object compile: 'h
	<debuggerCompleteToSender>
	Halt now'  ]
		runOnce: true.
	
	StartupAction
		name: 'Improvement in NEC'
		code: [ NECUntypedModel compile: 'initializeSelectors
	self resetSelectors.
	
	includeSelectors ifFalse: 
		[ Smalltalk keysAndValuesDo: [ :each :class |
			(each includesSubstring: narrowString caseSensitive: NECPreferences caseSensitive) ifTrue: [
			selectors add: (NECGlobalEntry contents: each)] ].
		^ self ].
	narrowString ifEmpty: [ ^ self ].
	NECSymbols 
		contains: narrowString
		caseSensitive: NECPreferences caseSensitive
		do: [ :each | 
			(includeVariables or: [ each first isLowercase ]) ifTrue: 
				[ selectors add: (NECSelectorEntry 
						contents: each
						type: #selector).
				selectors size > self listLimit ifTrue: [ ^ self ]]]' ]
		runOnce: true.
		
	StartupAction
		name: 'Backport FT2Handler correction'
		code: [ Object subclass: #FT2Handle
	slots: { #handle }
	classVariables: { #Registry. #Session. #DestroyMutex }
	poolDictionaries: 'FT2Constants'
	category: 'FreeType-Base'.
	
	FT2Handle class compile: 'register: aHandle
	(self registry includes: aHandle) ifTrue: [ ^ self ]. 
	self registry add: aHandle'.
	
	FT2Handle class compile: 'destroyMutex
	^ DestroyMutex ifNil: [ DestroyMutex := Mutex new ]'.
	
	FT2Handle compile: 'pvtDestroyHandle
		"This should only be sent from the finalizer. 
		 It runs inside a mutex because in strange cases it can happen that this is executed twice, 
		 causing a primitiveFailed to be raised."
		self class destroyMutex critical: [ | handleToRelease |
			self isValid ifFalse: [ ^self ].
			handleToRelease := self handle copy.
			self primDestroyHandle.
			"TODO this is bad, but it will prevent duplicated handles to be released"
			FT2Handle allSubInstancesDo: [ :each | 
				(handleToRelease = each handle) ifTrue: [ each beNull ] ] ]'
	]
	runOnce: true.
	
	StartupAction 
		name: 'Instance creation' 
		code: [  
	CategoryWidget class compile: 'instanceCreationMenu: aBuilder
		<nautilusGlobalProtocolMenu>
		(aBuilder item: #''Add instance creation...'')
			action: [ aBuilder model addInstanceCreation ];
			order: 90'.
		
	NautilusUI compile:
	 'addInstanceCreation
		| newName |
		self okToChange
			ifFalse: [ ^ self ].
		self selectedClass ifNil: [ ^ self ].
		newName := #''instance creation''.
		self selectedClass organization addCategory: newName before: self selectedCategory.
		self resetCategoriesListSelection.
		categoryWidget selectProtocol: newName.
		self selectedCategory: newName.
		self
			updateCategoryAndMethodList;
			giveFocusToSourceCode'] 
		runOnce: true.
		
	StartupAction
		name: 'Clean Monticello noise'
		code: [ | packages |
	packages := #('FreeType' 'Kernel' 'Komitter' 'NECompletion' 'Nautilus' 'Traits' '_UnpackagedPackage').
	MCWorkingCopy allInstances select: [ :p | packages includes: p package name ] thenDo: [ :p | p modified: false ] ]
	    runOnce: true.
		
	StartupAction
		name: 'Remove taskbar preview'
		code: [ TaskbarMorph showWindowPreview: false ]
	    runOnce: true.

}
