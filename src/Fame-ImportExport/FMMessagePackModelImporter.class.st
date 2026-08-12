Class {
	#name : 'FMMessagePackModelImporter',
	#superclass : 'FMImporter',
	#instVars : [
		'document'
	],
	#category : 'Fame-ImportExport-Importers',
	#package : 'Fame-ImportExport',
	#tag : 'Importers'
}

{ #category : 'importing' }
FMMessagePackModelImporter >> groupedRelations [

    | groupedRelations key |

    groupedRelations := Dictionary new.

    (document at: 'relations') do: [ :relationData |

        key := {
            relationData at: 'source'.
            relationData at: 'property'
        }.

        (groupedRelations
            at: key
            ifAbsentPut: [ OrderedCollection new ])
                add: relationData
    ].

    ^ groupedRelations
]

{ #category : 'importing' }
FMMessagePackModelImporter >> importFromFile: aFileReference [

    ^ aFileReference binaryReadStreamDo: [ :stream |
        self importFromStream: stream
    ]
]

{ #category : 'parsing' }
FMMessagePackModelImporter >> importFromStream: aStream [

    self beginDocument.

    self readDocumentFromStream: aStream.

    self restoreEntities.

    self restoreRelations.

    self endDocument.

    ^ model
]

{ #category : 'importing' }
FMMessagePackModelImporter >> readDocumentFromFile: aFileReference [

    ^ aFileReference binaryReadStreamDo: [ :stream |
        self readDocumentFromStream: stream
    ]
]

{ #category : 'importing' }
FMMessagePackModelImporter >> readDocumentFromStream: aStream [

    document := MpMessagePack unpack: aStream contents.

    ^ document
]

{ #category : 'importing' }
FMMessagePackModelImporter >> restoreAttributes: attributes into: anEntity [

	| meta property |
	meta := anEntity metadescription.

	attributes keysAndValuesDo: [ :propertyName :value |
			property := meta propertyNamed: propertyName.

			anEntity mmSetProperty: property to: value ].

	^ anEntity
]

{ #category : 'importing' }
FMMessagePackModelImporter >> restoreEntities [

    (document at: 'entities') do: [ :entityData |
        self restoreEntityFrom: entityData
    ]
]

{ #category : 'importing' }
FMMessagePackModelImporter >> restoreEntityFrom: entityData [

    | entity |

    entity := self
        createDirectEntityNamed: (entityData at: 'type')
        serial: (entityData at: 'id').

    self
        restoreAttributes: (entityData at: 'attributes')
        into: entity.

    ^ entity
]

{ #category : 'importing' }
FMMessagePackModelImporter >> restoreRelationFrom: relationData [

    | source target property |

    source := self
        entityAt: (relationData at: 'source')
        ifAbsent: [
            self error: 'Source entity not found'
        ].

    target := self
        entityAt: (relationData at: 'target')
        ifAbsent: [
            self error: 'Target entity not found'
        ].

    property := source mooseDescription
        propertyNamed: (relationData at: 'property').

    source
        mmSetProperty: property
        to: target.

    ^ source
]

{ #category : 'importing' }
FMMessagePackModelImporter >> restoreRelationGroup: relationGroup [

	| firstRelation source property targets |
	firstRelation := relationGroup first.

	source := self
		          entityAt: (firstRelation at: 'source')
		          ifAbsent: [ self error: 'Source entity not found' ].

	property := source metadescription propertyNamed:
		            (firstRelation at: 'property').

	targets := relationGroup collect: [ :relationData |
		           self targetForRelation: relationData ].

	property isMultivalued
		ifTrue: [ source mmSetProperty: property to: targets asArray ]
		ifFalse: [
				targets size = 1 ifFalse: [
					self error: 'Single-valued relation has multiple targets' ].

				source mmSetProperty: property to: targets first ].

	^ source
]

{ #category : 'importing' }
FMMessagePackModelImporter >> restoreRelations [

    self groupedRelations valuesDo: [ :relationGroup |
        self restoreRelationGroup: relationGroup
    ]
]

{ #category : 'importing' }
FMMessagePackModelImporter >> targetForRelation: relationData [

    (relationData includesKey: 'targetName') ifTrue: [
        ^ self metamodel
            elementNamed: (relationData at: 'targetName')
    ].

    ^ self
        entityAt: (relationData at: 'target')
        ifAbsent: [
            self error: 'Target entity not found'
        ]
]
