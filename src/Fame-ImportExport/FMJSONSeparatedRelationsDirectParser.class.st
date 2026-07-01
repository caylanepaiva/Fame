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
FMJSONSeparatedRelationsDirectParser >> DirectRelationPropertyOf: anEntity [
    "Reads one relation property such as: ""parentType"": {""ref"": 32}"

    | pos propertyName targetSerial targetEntity |

    pos := self position.

    propertyName := self String.
    propertyName ifNil: [ ^ self backtrack: pos ].

    self tPropertyNameSeparator ifFalse: [ ^ self backtrack: pos ].

    targetSerial := self referenceSerialValue.
    targetSerial ifNil: [ ^ self backtrack: pos ].

    targetEntity := importer elementAtSerial: targetSerial.

    self
        setRelationNamed: propertyName
        of: anEntity
        to: targetEntity.

    self tWHITESPACE.
    self tPropertySeparator.

    ^ true
]

{ #category : 'tokens' }
FMJSONSeparatedRelationsDirectParser >> Document [
	"Matches a separated relations JSON document: [ [entities], [relations] ]."

	self tWHITESPACE.

	importer beginDocument.
	self TwoPhaseMultiEntity.
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
FMJSONSeparatedRelationsDirectParser >> RelationCollection [
	"Reads the second inner array: relation objects for existing entities."

	self tMultiOPEN ifFalse: [ ^ self syntaxError ].

	[
		self RelationEntity and: [
				self incrementProgressBar.
				self tPropertySeparator ] ] whileTrue.

	self tMultiCLOSE ifFalse: [ ^ self syntaxError ].

	^ true
]

{ #category : 'tokens' }
FMJSONSeparatedRelationsDirectParser >> RelationEntity [ 

	| pos name serial entity| 
	pos:= self position.
	
	self tOPEN ifFalse: [ ^ self backtrack: pos ].
	
	name := self tFULLNAME.
	name ifNil: [ ^ self backtrack: pos ].

	self tPropertySeparator.
	
	serial := self serialValue.
	serial ifNil: [ ^ self syntaxError ].

	self tPropertySeparator.
	
	entity:= importer elementAtSerial: serial.
	
	[ self DirectRelationPropertyOf: entity  ] whileTrue.

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

    self tOPEN ifFalse: [ ^ self backtrack: position ].

    (self matchesWord: '"ref"')
        ifFalse: [ ^ self backtrack: position ].

    self tPropertyNameSeparator
        ifFalse: [ ^ self backtrack: position ].

    serial := self numberValue.
    serial ifNil: [ ^ self backtrack: position ].

    self tCLOSE ifFalse: [ ^ self backtrack: position ].

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

    | setter getter currentValue |

    setter := (propertyName , ':') asSymbol.

    (sourceEntity respondsTo: setter)
        ifTrue: [
            ^ sourceEntity
                perform: setter
                with: targetEntity ].

    getter := propertyName asSymbol.

    (sourceEntity respondsTo: getter)
        ifFalse: [
            self error:
                'Cannot set relation ',
                propertyName,
                ' on ',
                sourceEntity class name ].

    currentValue := sourceEntity perform: getter.

    (currentValue respondsTo: #add:)
        ifTrue: [ ^ currentValue add: targetEntity ].

    self error:
        'Relation ',
        propertyName,
        ' exists but is not settable on ',
        sourceEntity class name
]
