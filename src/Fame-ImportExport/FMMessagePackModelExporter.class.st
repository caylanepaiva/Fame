Class {
	#name : 'FMMessagePackModelExporter',
	#superclass : 'FMModelExporter',
	#category : 'Fame-ImportExport-Exporters',
	#package : 'Fame-ImportExport',
	#tag : 'Exporters'
}

{ #category : 'exporting' }
FMMessagePackModelExporter >> exportToFile: aFileReference [

    | stream |

    stream := aFileReference binaryWriteStream.

    [
        stream nextPutAll: self messagePackBytes
    ] ensure: [
        stream close
    ].

    ^ aFileReference
]

{ #category : 'exporting' }
FMMessagePackModelExporter >> messagePackBytes [

    ^ MpMessagePack pack: self messagePackDocument
]

{ #category : 'exporting' }
FMMessagePackModelExporter >> messagePackDocument [

    | entities relations |

    entities := self messagePackEntities.
    relations := self messagePackRelations.

    ^ {
        'format' -> 'moose-messagepack'.
        'version' -> 1.
        'entities' -> entities.
        'relations' -> relations
    } asDictionary
]

{ #category : 'exporting' }
FMMessagePackModelExporter >> messagePackEntities [

    ^ (model entities collect: [ :each |
        self messagePackEntityFor: each
    ]) asArray
]

{ #category : 'exporting' }
FMMessagePackModelExporter >> messagePackEntityFor: anEntity [

	| meta |
	meta := anEntity metadescription.

	^ {
		  ('id' -> (self indexOf: anEntity)).
		  ('type' -> meta fullName asString).
		  ('attributes' -> (self primitiveAttributesOf: anEntity)) }
		  asDictionary
]

{ #category : 'exporting' }
FMMessagePackModelExporter >> messagePackRelationFrom: source property: property target: target [

    | relation |

    relation := {
        'source' -> (self indexOf: source).
        'property' -> property name asString
    } asDictionary.

    (FM3Constant constants includes: target)
        ifTrue: [
            relation
                at: 'targetName'
                put: target name asString
        ]
        ifFalse: [
            relation
                at: 'target'
                put: (self indexOf: target)
        ].

    ^ relation
]

{ #category : 'exporting' }
FMMessagePackModelExporter >> messagePackRelations [

    ^ (model entities
        flatCollect: [ :each |
            self messagePackRelationsOf: each
        ]) asArray
]

{ #category : 'exporting' }
FMMessagePackModelExporter >> messagePackRelationsOf: anEntity [

	| meta relationProperties relations value values |
	meta := anEntity metadescription.
	relations := OrderedCollection new.

	relationProperties := (self sortedPropertiesOf: meta) select: [
			                      :property |
			                      (self shouldIgnoreProperty: property) not
				                      and: [ property type isPrimitive not ] ].

	relationProperties do: [ :property |
			value := anEntity mmGetProperty: property.

			value ifNotNil: [
					values := property isMultivalued
						          ifTrue: [ value ]
						          ifFalse: [ { value } ].

					(values reject: [ :each | each asString = 'unavailable' ]) do: [
							:target |
							relations add: (self
									 messagePackRelationFrom: anEntity
									 property: property
									 target: target) ] ] ].

	^ relations asArray
]

{ #category : 'exporting' }
FMMessagePackModelExporter >> primitiveAttributesOf: anEntity [

	| meta attributes properties value validValues |
	meta := anEntity metadescription.
	attributes := Dictionary new.

	properties := (self sortedPropertiesOf: meta) select: [ :property |
			              (self shouldIgnoreProperty: property) not and: [
				              property type isPrimitive ] ].

	properties do: [ :property |
			value := anEntity mmGetProperty: property.

			value ifNotNil: [
					property isMultivalued
						ifTrue: [
								validValues := value reject: [ :each |
									               each isNil or: [
										               each asString = 'unavailable' ] ].

								validValues ifNotEmpty: [
									attributes
										at: property name asString
										put: validValues asArray ] ]
						ifFalse: [
								value asString = 'unavailable' ifFalse: [
									attributes at: property name asString put: value ] ] ] ].

	^ attributes
]
