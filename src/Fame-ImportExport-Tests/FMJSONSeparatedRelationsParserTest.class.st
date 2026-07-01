"
A FMJSONSeparatedRelationsParserTest is a test class for testing the behavior of FMJSONSeparatedRelationsParser
"
Class {
	#name : 'FMJSONSeparatedRelationsParserTest',
	#superclass : 'TestCase',
	#instVars : [
		'importer',
		'famixModel',
		'fmmodel'
	],
	#category : 'Fame-ImportExport-Tests-Importers',
	#package : 'Fame-ImportExport-Tests',
	#tag : 'Importers'
}

{ #category : 'running' }
FMJSONSeparatedRelationsParserTest >> import: aString rule: aSelector [

	| configuredImporter |

	configuredImporter := importer parser new.
	configuredImporter stream: aString readStream.
	configuredImporter importer: importer.

	configuredImporter perform: aSelector
]

{ #category : 'running' }
FMJSONSeparatedRelationsParserTest >> newEntity: entity id: id [

	importer assign: entity to: id
]

{ #category : 'running' }
FMJSONSeparatedRelationsParserTest >> setUp [

	super setUp.

	famixModel := FamixJavaModel new
		name: 'JavaModel for test';
		yourself.
	fmmodel := FMModel withMetamodel: famixModel metamodel.
	importer := (FMImporter model: fmmodel)
		parser: FMJSONSeparatedRelationsParserToexclude;
		beginDocument ;
		yourself
]

{ #category : 'tests' }
FMJSONSeparatedRelationsParserTest >> testImportClassAndProperty [

	self import: '{
	"FM3":"Famix-Java-Entities.Class",
	"id":32,
	"name":"AClazz",
	"isStub":false
	}'
	rule: #Entity.

	self
		assert: (importer elementAtSerial: 32) class
		equals: FamixJavaClass.
	self assert: (importer elementAtSerial: 32) name equals: 'AClazz'.
	self deny: (importer elementAtSerial: 32) isStub
]

{ #category : 'tests' }
FMJSONSeparatedRelationsParserTest >> testImportMultiEntity [

	self
		import: '[
	{"FM3":"Famix-Java-Entities.Class",
	"id":1,
	"name":"AClazz"
	},
	{"FM3":"Famix-Java-Entities.Method",
	"id":2,
	"name":"meth"
	}]'
		rule: #MultiEntity.

	self assert: (importer elementAtSerial: 1) class equals: FamixJavaClass.
	self assert: (importer elementAtSerial: 1) name equals: 'AClazz'.
	self assert: (importer elementAtSerial: 2) class equals: FamixJavaMethod.
	self assert: (importer elementAtSerial: 2) name equals: 'meth'.
]

{ #category : 'tests' }
FMJSONSeparatedRelationsParserTest >> testImportMultiRelation [

	| entity1 entity2 entity3 entity4 |
	entity1 := famixModel newClass.
	entity2 := famixModel newMethod.
	entity3 := famixModel newMethod.
	entity4 := famixModel newEntityTyping.
	self newEntity: entity1 id: 1.
	self newEntity: entity2 id: 2.
	self newEntity: entity3 id: 3.
	self newEntity: entity4 id: 4.

	self
		import: '[
	{"FM3":"Famix-Java-Entities.Method",
	"id":2,
	"parentType": {"ref": 1},
	"typing": {"ref": 4}}
	,
	{"FM3":"Famix-Java-Entities.Method",
	"id":3,
	"parentType": {"ref": 1}
	}]'
		rule: #MultiEntity.

	self assert: entity2 parentType equals: entity1.
	self assert: entity2 typing equals: entity4.
	self assert: entity3 parentType equals: entity1
]

{ #category : 'tests' }
FMJSONSeparatedRelationsParserTest >> testImportRelation [

	| entity1 entity2 |
	entity1 := famixModel newClass.
	entity2 := famixModel newMethod.
	self newEntity: entity1 id: 1.
	self newEntity: entity2 id: 2.
	self
		import: '{
	"FM3":"Famix-Java-Entities.Method",
	"id":2,
	"parentType": {"ref": 1}
	}'
		rule: #Entity.

	self assert: entity2 parentType equals: entity1
]
