Class {
	#name : 'Experiments',
	#superclass : 'Object',
	#instVars : [
		'input',
		'output',
		'repetitions',
		'language',
		'format',
		'operation',
		'computer',
		'os',
		'powerMode',
		'charging',
		'notes',
		'importSelector',
		'experimentId',
		'results',
		'implementationName'
	],
	#category : 'Fame-ImportExport',
	#package : 'Fame-ImportExport'
}

{ #category : 'writing' }
Experiments class >> experimentImport: fileInput to: fileOutput for: numberRepetitions [

	^ self new
		file: fileInput;
		output: fileOutput;
		repetitions: numberRepetitions;
		run
]

{ #category : 'as yet unclassified' }
Experiments class >> experimentImport: fileInput to: fileOutput for: numberOfRepetitions using: anImportSelector named: anImplementationName [

	| experiment |
	experiment := self new.

	experiment
		file: fileInput asFileReference;
		output: fileOutput asFileReference;
		repetitions: numberOfRepetitions;
		importSelector: anImportSelector;
		implementationName: anImplementationName.

	^ experiment run
]

{ #category : 'writing' }
Experiments >> averageResultRow [

	^ {
		DateAndTime now printString.
		experimentId.
		input basenameWithoutExtension.
		language.
		format.
		'average import'.
		'average'.
		self averageTimeMs.
		''.
		''.
		''.
		[ input size ] on: Error do: [ :e | '' ].
		input fullName.
		computer.
		os.
		powerMode.
		charging.
		notes
	}
]

{ #category : 'writing' }
Experiments >> averageTimeMs [

	| times average |

	times := results collect: [ :row | row at: 8 ].

	times ifEmpty: [ ^ 0.0 ].

	average := (times sum / times size) asFloat.

	^ average roundTo: 0.01
]

{ #category : 'writing' }
Experiments >> csvEscape: value [

	| text |

	text := value isNil
		ifTrue: [ '' ]
		ifFalse: [ value asString ].

	^ '"', (text copyReplaceAll: '"' with: '""'), '"'
]

{ #category : 'setup' }
Experiments >> csvReader [
^ {
    'timestamp'.
    'experiment_id'.
    'model_name'.
    'language'.
    'format'.
    'operation'.
    'run_number'.
    'time_ms'.
    'entities'.
    'classes'.
    'methods'.
    'file_size_bytes'.
    'input_path'.
    'computer'.
    'os'.
    'power_mode'.
    'charging'.
    'notes'
}.
]

{ #category : 'accessing' }
Experiments >> file: aFileReferenceOrString [

	input := aFileReferenceOrString asFileReference.
	^ self
]

{ #category : 'accessing' }
Experiments >> format: aString [

	format := aString.
	^ self
]

{ #category : 'accessing' }
Experiments >> implementationName: aString [

	implementationName := aString
]

{ #category : 'setup' }
Experiments >> importModel [

    | model |

    self isBinaryImport
        ifTrue: [
            input binaryReadStreamDo: [ :stream |
                model := FamixJavaModel
                    perform: importSelector
                    with: stream
            ]
        ]
        ifFalse: [
            input readStreamDo: [ :stream |
                model := FamixJavaModel new
                    perform: importSelector
                    with: stream
            ]
        ].

    ^ model
]

{ #category : 'accessing' }
Experiments >> importSelector: aSelector [

	importSelector := aSelector
]

{ #category : 'initialization' }
Experiments >> initialize [

	super initialize.
	results := OrderedCollection new.
	importSelector := #importFromJSONSeparetedStream:.
	implementationName := 'separated-current'
]

{ #category : 'testing' }
Experiments >> isBinaryImport [

    ^ {
        #importFromFuelStream:.
        #importFromMessagePackStream:
    } includes: importSelector
]

{ #category : 'accessing' }
Experiments >> notes: aString [

	notes := aString.
	^ self
]

{ #category : 'accessing' }
Experiments >> output: aFileReferenceOrString [

	output := aFileReferenceOrString asFileReference.
	^ self
]

{ #category : 'accessing' }
Experiments >> repetitions: anInteger [

	repetitions := anInteger.
	^ self
]

{ #category : 'accessing' }
Experiments >> run [

	output parent ensureCreateDirectory.
	experimentId := DateAndTime now printString.

	1 to: repetitions do: [ :runNumber |
	self runOneImportExperiment: runNumber ].

	self writeResultsToCsv.

	^ {
		  ('csv_file' -> output fullName).
		  ('new_results' -> results).
		  ('average_time_ms' -> self averageTimeMs)
		 }
]

{ #category : 'writing' }
Experiments >> runOneImportExperiment: runNumber [
	| model time fileSize entityCount classCount methodCount |

	Smalltalk garbageCollect.

	fileSize := [ input size ] on: Error do: [ :e | '' ].

	time := Time millisecondsToRun: [
		model := self importModel
	].

	entityCount := [ model entities size ] on: Error do: [ :e | '' ].
	classCount := [ model allClasses size ] on: Error do: [ :e | '' ].
	methodCount := [ model allMethods size ] on: Error do: [ :e | '' ].
	
		results add: {
		DateAndTime now printString.
		experimentId.
		input basenameWithoutExtension.
		language.
		format.
		operation.
		runNumber.
		time.
		entityCount.
		classCount.
		methodCount.
		fileSize.
		input fullName.
		computer.
		os.
		powerMode.
		charging.
		notes
	}

]

{ #category : 'writing' }
Experiments >> writeCsvRow: values on: stream [

	values withIndexDo: [ :each :index |
		index > 1 ifTrue: [
			stream nextPut: $,
		].
		stream nextPutAll: (self csvEscape: each)
	].

	stream cr.
]

{ #category : 'writing' }
Experiments >> writeResultsToCsv [

	| oldContent |
	oldContent := output exists
		              ifTrue: [ output contents ]
		              ifFalse: [ '' ].

	output writeStreamDo: [ :stream |
			oldContent isEmpty
				ifTrue: [ self writeCsvRow: self csvReader on: stream ]
				ifFalse: [
						stream nextPutAll: oldContent.
						(oldContent last = Character lf or: [
							 oldContent last = Character cr ]) ifFalse: [ stream cr ] ].

			results do: [ :row |
			self writeCsvRow: row on: stream
		].

		self writeCsvRow: self averageResultRow on: stream
	].
]
