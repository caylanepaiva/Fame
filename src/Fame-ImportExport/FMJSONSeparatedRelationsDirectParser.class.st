"
implementation without future entity class
"
Class {
	#name : 'FMJSONSeparatedRelationsDirectParser',
	#superclass : 'FMJSONParser',
	#category : 'Fame-ImportExport-Traits',
	#package : 'Fame-ImportExport',
	#tag : 'Traits'
}

{ #category : 'tokens' }
FMJSONSeparatedRelationsDirectParser >> DirectMultiRelationValueOf: anEntity named: propertyName [

    | pos targetSerial targetEntity |

    pos := self position.

    self tMultiOPEN ifFalse: [ ^ self backtrack: pos ].

    [
        targetSerial := self referenceSerialValue.
        targetSerial
            ifNil: [ false ]
            ifNotNil: [
                targetEntity := importer elementAtSerial: targetSerial.

                self
                    setRelationNamed: propertyName
                    of: anEntity
                    to: targetEntity.

                self tPropertySeparator ]
    ] whileTrue.

    self tMultiCLOSE ifFalse: [ ^ self syntaxError ].

    self tWHITESPACE.
    ^ true
]

{ #category : 'tokens' }
FMJSONSeparatedRelationsDirectParser >> DirectRelationPropertyOf: anEntity [
    "Reads one relation property and applies it directly."

    | pos propertyName |

    pos := self position.

    propertyName := self String.
    propertyName ifNil: [ ^ self backtrack: pos ].

    self tPropertyNameSeparator ifFalse: [ ^ self backtrack: pos ].

    (self DirectRelationValueOf: anEntity named: propertyName)
        ifFalse: [ ^ self backtrack: pos ].

    self tWHITESPACE.
    self tPropertySeparator.

    ^ true
]

{ #category : 'tokens' }
FMJSONSeparatedRelationsDirectParser >> DirectRelationValueOf: anEntity named: propertyName [

    ^ (self DirectSingleRelationValueOf: anEntity named: propertyName)
        or: [ self DirectMultiRelationValueOf: anEntity named: propertyName ]
]

{ #category : 'tokens' }
FMJSONSeparatedRelationsDirectParser >> DirectSingleRelationValueOf: anEntity named: propertyName [

    | targetSerial targetEntity |

    targetSerial := self referenceSerialValue.
    targetSerial ifNil: [ ^ false ].

    targetEntity := importer elementAtSerial: targetSerial.

    self
        setRelationNamed: propertyName
        of: anEntity
        to: targetEntity.

    ^ true
]

{ #category : 'tokens' }
FMJSONSeparatedRelationsDirectParser >> Document [
	"Matches a separated JSON document."

	self tWHITESPACE.

	self atEnd
		ifTrue: [ importer beginDocument ]
		ifFalse: [
			importer beginDocument.

			self tMultiOPEN ifFalse: [ ^ self syntaxError ].

			self EntityDefinitionCollection ifFalse: [ ^ self syntaxError ].

			self tPropertySeparator ifFalse: [ ^ self syntaxError ].

			self RelationCollection ifFalse: [ ^ self syntaxError ].

			self tMultiCLOSE ifFalse: [ ^ self syntaxError ]
		].

	importer endDocument.
	self tWHITESPACE.
	^ true
]

{ #category : 'tokens' }
FMJSONSeparatedRelationsDirectParser >> Entity [
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
FMJSONSeparatedRelationsDirectParser >> EntityCollection [
	"Reads the first inner array: entities with primitive attributes."

	self tMultiOPEN ifFalse: [ ^ self syntaxError ].

	[
		self Entity and: [
				self incrementProgressBar.
				self tPropertySeparator ] ] whileTrue.

	self tMultiCLOSE ifFalse: [ ^ self syntaxError ].

	^ true
]

{ #category : 'tokens' }
FMJSONSeparatedRelationsDirectParser >> EntityDefinitionCollection [
	"Reads the first inner array: entities with FM3."

	self tMultiOPEN ifFalse: [ ^ self syntaxError ].

	[
		self Entity
			ifTrue: [
				self incrementProgressBar.
				self tPropertySeparator ]
			ifFalse: [ false ]
	] whileTrue.

	self tMultiCLOSE ifFalse: [ ^ self syntaxError ].

	^ true
]

{ #category : 'tokens' }
FMJSONSeparatedRelationsDirectParser >> RelationCollection [
	"Reads the second inner array: relations without FM3."

	self tMultiOPEN ifFalse: [ ^ self syntaxError ].

	[
		self RelationEntity
			ifTrue: [
				self incrementProgressBar.
				self tPropertySeparator ]
			ifFalse: [ false ]
	] whileTrue.

	self tMultiCLOSE ifFalse: [ ^ self syntaxError ].

	^ true
]

{ #category : 'tokens' }
FMJSONSeparatedRelationsDirectParser >> RelationEntity [
	"Reads one relation object without FM3 and applies its relations"

	| pos serial entity |
	pos := self position.

	self tOPEN ifFalse: [ ^ self backtrack: pos ].

	serial := self serialValue.
	serial ifNil: [ ^ self syntaxError ].

	entity := importer elementAtSerial: serial.

	self tPropertySeparator.

	[ self DirectRelationPropertyOf: entity ] whileTrue.

	self tCLOSE ifFalse: [ ^ self syntaxError ].

	self tWHITESPACE.

	^ true
]

{ #category : 'tokens' }
FMJSONSeparatedRelationsDirectParser >> TwoPhaseMultiEntity [
	"Reads: [ [entities], [relations] ]"

	self tMultiOPEN ifFalse: [ ^ self syntaxError ].

	self EntityCollection.

	self tPropertySeparator ifFalse: [ ^ self syntaxError ].

	self RelationCollection.

	self tMultiCLOSE ifFalse: [ ^ self syntaxError ].

	^ true
]

{ #category : 'tokens' }
FMJSONSeparatedRelationsDirectParser >> numberValue [
    "Reads an integer number and returns it."

    | position numberString |

    position := self position.

    buffer reset.

    chararacter = $- ifTrue: [
        buffer nextPut: chararacter.
        self next ].

    [ chararacter notNil and: [ chararacter isDigit ] ] whileTrue: [
        buffer nextPut: chararacter.
        self next ].

    numberString := buffer contents.
    numberString isEmpty ifTrue: [ ^ self backtrack: position ].

    self tWHITESPACE.
    ^ numberString asNumber
]

{ #category : 'tokens' }
FMJSONSeparatedRelationsDirectParser >> referenceSerialValue [
    "Reads a reference object: {""ref"": 32} and returns 32."

    | position serial |

    position := self position.

    self tOPEN ifFalse: [
        self backtrack: position.
        ^ nil ].

    (self matchesWord: '"ref"') ifFalse: [
        self backtrack: position.
        ^ nil ].

    self tPropertyNameSeparator ifFalse: [
        self backtrack: position.
        ^ nil ].

    serial := self numberValue.
    serial ifNil: [
        self backtrack: position.
        ^ nil ].

    self tCLOSE ifFalse: [
        self backtrack: position.
        ^ nil ].

    self tWHITESPACE.
    ^ serial
]

{ #category : 'tokens' }
FMJSONSeparatedRelationsDirectParser >> serialValue [
    "Reads ""id"": 5 and returns 5 without registering it in the importer."

    | position serial |

    position := self position.

    self tID ifFalse: [ ^ self backtrack: position ].
    self tPropertyNameSeparator ifFalse: [ ^ self backtrack: position ].

    serial := self numberValue.
    serial ifNil: [ ^ self backtrack: position ].

    ^ serial
]

{ #category : 'tokens' }
FMJSONSeparatedRelationsDirectParser >> setRelationNamed: propertyName of: sourceEntity to: targetEntity [
    "Sets a relation directly without FMFutureEntity/FMFutureProperty."

    | getter setter currentValue |

    getter := propertyName asSymbol.

    (sourceEntity respondsTo: getter)
        ifTrue: [
            currentValue := sourceEntity perform: getter.

            (currentValue respondsTo: #add:)
                ifTrue: [ ^ currentValue add: targetEntity ] ].

    setter := (propertyName , ':') asSymbol.

    (sourceEntity respondsTo: setter)
        ifTrue: [
            ^ sourceEntity
                perform: setter
                with: targetEntity ].

    self error:
        'Cannot set relation ',
        propertyName,
        ' on ',
        sourceEntity class name
]
