Class {
	#name : 'FMJSONSeparatedRelationsWithFMFuture',
	#superclass : 'FMJSONParser',
	#category : 'Fame-ImportExport-Traits',
	#package : 'Fame-ImportExport',
	#tag : 'Traits'
}

{ #category : 'tokens' }
FMJSONSeparatedRelationsWithFMFuture >> Document [
    "Matches a separated relations JSON document: [ [entities], [relations] ]."

    self tWHITESPACE.

    importer beginDocument.
    self TwoPhaseMultiEntity.
    importer endDocument.

    self tWHITESPACE.
    ^ true
]

{ #category : 'tokens' }
FMJSONSeparatedRelationsWithFMFuture >> Entity [
    "Reads one entity from the first collection and creates a new instance."

    | pos name |

    pos := self position.

    self tOPEN ifFalse: [ ^ self backtrack: pos ].

    name := self tFULLNAME.
    name ifNil: [ ^ self backtrack: pos ].

    self tPropertySeparator.

    importer inEntity: name do: [
        self Serial.
        self tPropertySeparator.
        [ self Property ] whileTrue.
        self tCLOSE ifFalse: [ ^ self syntaxError ] ].

    self tWHITESPACE.
    ^ true
]

{ #category : 'tokens' }
FMJSONSeparatedRelationsWithFMFuture >> EntityCollection [
    "Reads the first inner array: entities with primitive attributes."

    self tMultiOPEN ifFalse: [ ^ self syntaxError ].

    [
        self Entity and: [
            self incrementProgressBar.
            self tPropertySeparator ]
    ] whileTrue.

    self tMultiCLOSE ifFalse: [ ^ self syntaxError ].

    ^ true
]

{ #category : 'tokens' }
FMJSONSeparatedRelationsWithFMFuture >> RelationCollection [
    "Reads the second inner array: relation objects for existing entities."

    self tMultiOPEN ifFalse: [ ^ self syntaxError ].

    [
        self RelationEntity and: [
            self incrementProgressBar.
            self tPropertySeparator ]
    ] whileTrue.

    self tMultiCLOSE ifFalse: [ ^ self syntaxError ].

    ^ true
]

{ #category : 'tokens' }
FMJSONSeparatedRelationsWithFMFuture >> RelationEntity [
    "Reads one relation object and applies its properties to an existing entity."

    | pos name serial |

    pos := self position.

    self tOPEN ifFalse: [ ^ self backtrack: pos ].

    name := self tFULLNAME.
    name ifNil: [ ^ self backtrack: pos ].

    self tPropertySeparator.

    serial := self serialValue.
    serial ifNil: [ ^ self syntaxError ].

    self tPropertySeparator.

    importer beginExistingEntity: name serial: serial.

    [ self Property ] whileTrue.

    self tCLOSE ifFalse: [ ^ self syntaxError ].

    importer endExistingEntity: name.

    self tWHITESPACE.
    ^ true
]

{ #category : 'tokens' }
FMJSONSeparatedRelationsWithFMFuture >> TwoPhaseMultiEntity [
    "Reads: [ [entities], [relations] ]"

    self tMultiOPEN ifFalse: [ ^ self syntaxError ].

    self EntityCollection.

    self tPropertySeparator ifFalse: [ ^ self syntaxError ].

    self RelationCollection.

    self tMultiCLOSE ifFalse: [ ^ self syntaxError ].

    ^ true
]

{ #category : 'tokens' }
FMJSONSeparatedRelationsWithFMFuture >> serialValue [
    "Reads the id value and returns it without registering it in the importer."

    | position serialString |

    position := self position.

    self tID ifFalse: [ ^ self backtrack: position ].
    self tPropertyNameSeparator ifFalse: [ ^ self backtrack: position ].

    buffer reset.

    chararacter = $- ifTrue: [
        buffer nextPut: chararacter.
        self next ].

    [ chararacter notNil and: [ chararacter isDigit ] ] whileTrue: [
        buffer nextPut: chararacter.
        self next ].

    serialString := buffer contents.
    serialString isEmpty ifTrue: [ ^ self backtrack: position ].

    self tWHITESPACE.

    ^ serialString asNumber
]
