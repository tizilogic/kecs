package kecs;

import kecs.Component;
import kecs.World;


@:coreType abstract ClassKey from Class<Dynamic> to {} {}

/**
 * Entity is a container for a set of `kecs.Component`
 */
@:allow(kecs.World, kecs.System)
class Entity {
    private static var currentId:Int = 0;

    public var c(get, null):Map<ClassKey, Component>;

    private var myWorld:World;
    private var id:Int;
    private var components:Map<ClassKey, Component>;
    private var addedComponents:Map<ClassKey, Component>;
    private var droppedComponents:Array<ClassKey>;

    public function new(world:World) {
        myWorld = world;
        id = currentId;
        ++currentId;
        components = [];
        addedComponents = [];
        droppedComponents = [];
    }

    /**
     * Add a Component to this Entity
     * @param component
     */
    public inline function addComponent(component:Component) {
        var t = Type.getClass(component);
        if (components.exists(t) && !droppedComponents.contains(t)) {
            throw "Component type is already part of this Entity: " + Type.getClassName(t);
        }
        if (addedComponents.exists(t)) {
            throw "Component type is already being added to this Entity: " + Type.getClassName(t);
        }
        if (!addedComponents.keys().hasNext()) {
            myWorld.registerEntityForAddFlush(this);
        }
        addedComponents[t] = component;
    }

    /**
     * Get a Component of this Entity by its Type
     * @param componentT
     * @return Component
     */
    public function getComponent<T:Component>(componentT:Class<T>):T {
        var c:T = cast components[componentT];
        if (c == null) {
            throw "Component type not present in this Entity: " + Type.getClassName(componentT);
        }
        return c;
    }

    function get_c():Map<ClassKey, Component> {
        return components;
    }

    /**
     * Whether there is a Component of the specified Type present
     * @param componentT
     * @return Bool
     */
    public inline function hasComponent<T:Component>(componentT:Class<T>):Bool {
        return components.exists(componentT);
    }

    /**
     * Remove a Component from this Entity
     * @param componentT
     */
    public inline function removeComponent<T:Component>(componentT:Class<T>) {
        if (!hasComponent(componentT)) {
            throw "Component type not present in this Entity: " + Type.getClassName(componentT);
        }
        if (droppedComponents.length == 0) {
            myWorld.registerEntityForRemoveFlush(this);
        }
        droppedComponents.push(componentT);
    }

    // Deferred component updates

    private inline function getPostRemovalComponentTypes():Array<ClassKey> {
        var arr = [for (c in components.keys()) c];
        for (c in droppedComponents) {
            arr.remove(c);
        }
        return arr;
    }

    private inline function getPostAdditionComponentTypes():Array<ClassKey> {
        var arr = [for (c in components.keys()) c];
        for (c in addedComponents.keys()) {
            arr.push(c);
        }
        return arr;
    }

    private inline function flushRemovals() {
        for (c in droppedComponents) {
            components.remove(c);
        }
        droppedComponents.resize(0);
    }

    private inline function flushAdditions() {
        for (c in addedComponents.keys()) {
            components[c] = addedComponents[c];
        }
        addedComponents.clear();
    }

    private inline function destroy() {
        for (c in components.keys()) {
            removeComponent(cast c);
        }
    }

    public inline function toString():String {
        return myWorld.entityName[this];
    }
}
