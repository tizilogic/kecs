package kecs;

import kecs.Entity;
import kecs.System;


/**
 * The World is the root of the ECS. A world contains a set of `kecs.Entity` and
 * a set of `kecs.System`. The `update()` method of a world ensures that all the
 * systems' `update()` are called.
 */
@:allow(kecs)
class World {
    private var entities:Map<Int, Entity>;
    private var systems:Map<Int, System>;
    private var addPool:Array<Entity>;
    private var delPool:Array<Entity>;
    private var entityName:Map<Entity, String>;
    private var sortArr:Array<Int>;

    public function new() {
        entities = [];
        systems = [];
        addPool = [];
        delPool = [];
        entityName = [];
        sortArr = [];
    }

    /**
     * Create a new Entity in this World.
     * @param components Components to be used for this Entity
     * @param name Optional name for debugging purposes
     * @return Entity
     */
    public function createEntity(components:Array<Component>, ?name:String = null):Entity {
        var entity = new Entity(this);
        entities[entity.id] = entity;
        for (comp in components) {
            entity.addComponent(comp);
        }
        if (name != null) {
            entityName[entity] = name;
        }
        else {
            entityName[entity] = "Entity " + entity.id;
        }
        return entity;
    }

    /**
     * Retrieve an Entity from this world by its `id`.
     * @param id
     */
    public function getEntity(id:Int) {
        if (entities.exists(id)) {
            return entities[id];
        }
        throw "No entity present with id = " + id;
    }

    /**
     * Remove an Entity from this world either by providing its `id` or the instance itself.
     * @param id
     * @param entity
     */
    public function removeEntity(?id:Int = -1, ?entity:Entity = null) {
        if (entity != null) {
            id = entity.id;
        }
        if (id < 0) {
            throw "No entity present with id = " + id;
        }
        delPool.push(entities[id]);
    }

    /**
     * Add a System to this World.
     * @param system
     * @param sort Defines the order of execution during World update cycles.
     */
    public function addSystem(system:System, sort:Int) {
        if (systems.exists(sort)) {
            throw "A system with sort " + sort + " already exists";
        }
        systems[sort] = system;
        system.myWorld = this;
        sortArr.push(sort);
        sortArr.sort(cmp);

        flushComponentUpdates();
        for (id in entities.keys()) {
            system.proposeAdd(entities[id]);
        }
    }

    /**
     * Check whether this World has a system of the specified type.
     * @param systemT
     * @return Bool
     */
    public function hasSystem<T:System>(systemT:Class<T>):Bool {
        for (id in systems.keys()) {
            if (Type.getClassName(Type.getClass(systems[id])) == Type.getClassName(systemT)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Return the System instance of the given system type.
     * @param systemT
     * @return System
     */
    public function getSystem<T:System>(systemT:Class<T>):T{
        for (id in systems.keys()) {
            if (Type.getClassName(Type.getClass(systems[id])) == Type.getClassName(systemT)) {
                return cast systems[id];
            }
        }
        throw "Unable to find a matching System";
    }

    /**
     * Remove a System from this World.
     * @param systemT The derived class of the System to remove
     */
    public function removeSystem<T:System>(systemT:Class<T>) {
        for (id in systems.keys()) {
            if (Type.getClassName(Type.getClass(systems[id])) == Type.getClassName(systemT)) {
                systems[id].destroy();
                systems.remove(id);
                sortArr.remove(id);
                return;
            }
        }
        throw "Unable to find a matching System to remove";
    }

    /**
     * Run all systems in ascending order of sort.
     */
    public inline function update() {
        for (sort in sortArr) {
            flushComponentUpdates();
            systems[sort].update();
        }
    }

    private static inline function cmp(a:Int, b:Int):Int {
        return a > b ? 1 : a < b ? -1 : 0;
    }

    private function flushComponentUpdates() {
        while (addPool.length + delPool.length > 0) {
            while (delPool.length > 0) {
                removalFlush();
            }
            addFlush();
        }
    }

    private function removalFlush() {
        var removalPool = delPool.copy();
        delPool.resize(0);

        for (entity in removalPool) {
            for (sort in systems.keys()) {
                systems[sort].proposeRemoval(entity);
            }
            entity.flushRemovals();
        }
    }

    private function addFlush() {
        var additionPool = addPool.copy();
        addPool.resize(0);

        for (entity in additionPool) {
            entity.flushAdditions();
            for (sort in systems.keys()) {
                systems[sort].proposeAdd(entity);
            }
        }
    }

    private function registerEntityForAddFlush(entity:Entity) {
        addPool.push(entity);
    }

    private function registerEntityForRemoveFlush(entity:Entity) {
        delPool.push(entity);
    }
}
