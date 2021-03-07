package kecs;

import kecs.Component;
import kecs.CustomTypes;
import kecs.World;


/**
 * Entity is a container for a set of `kecs.Component`
 */
@:allow(kecs.World, kecs.System)
class Entity {
    private static var currentId:Int = 0;

    public var c(get, null):Map<ComponentType, Component>;

    private var myWorld:World;
    private var id:Int;
    private var components:Map<ComponentType, Component>;
    private var addedComponents:Map<ComponentType, Component>;
    private var droppedComponents:Array<ComponentType>;

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
        var t = Type.getClassName(Type.getClass(component));
        if (components.exists(t) && !droppedComponents.contains(t)) {
            throw "Component type is already part of this Entity";
        }
        if (addedComponents.exists(t)) {
            throw "Component type is already being added to this Entity";
        }
        if (!addedComponents.keys().hasNext()) {
            myWorld.registerEntityForAddFlush(this);
        }
        addedComponents[t] = component;
    }

    /**
     * Get a Component of this Entity by its Type
     * @param componentT
     */
    public inline function getComponent(componentT:ComponentType) {
        if (components.exists(componentT)) {
            return components[componentT];
        }
        throw "Component type not present in this Entity";
    }

    /**
     * Whether there is a Component of the specified Type present
     * @param componentT
     * @return Bool
     */
    public inline function hasComponent(componentT:ComponentType):Bool {
        return components.exists(componentT);
    }

    /**
     * Remove a Component from this Entity
     * @param componentT
     */
    public inline function removeComponent(componentT:ComponentType) {
        if (!hasComponent(componentT)) {
            throw "Component type not present in this Entity";
        }
        if (droppedComponents.length == 0) {
            myWorld.registerEntityForRemoveFlush(this);
        }
        droppedComponents.push(componentT);
    }

    private inline function get_c():Map<ComponentType, Component> {
        return components;
    }

    // Deferred component updates

    private inline function getPostRemovalComponentTypes():Array<ComponentType> {
        var arr = [for (c in components.keys()) c];
        for (c in droppedComponents) {
            arr.remove(c);
        }
        return arr;
    }

    private inline function getPostAdditionComponentTypes():Array<ComponentType> {
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
            removeComponent(c);
        }
    }

    public inline function toString():String {
        return myWorld.entityName[this];
    }
}
