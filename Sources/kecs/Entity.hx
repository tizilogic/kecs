package kecs;

import kecs.Component;
import kecs.World;


/**
 * Entity is a container for a set of `kecs.Component`
 */
@:allow(kecs.World, kecs.System)
class Entity {
    private static var currentId:Int = 0;

    private var myWorld:World;
    private var id:Int;
    private var components:Map<String, Component>;
    private var addedComponents:Map<String, Component>;
    private var droppedComponents:Array<String>;

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
        var name = Type.getClassName(Type.getClass(component));
        if (components.exists(name) && !droppedComponents.contains(name)) {
            trace("ERROR: Component type is already part of this Entity: " + name);
            return;
        }
        if (addedComponents.exists(name)) {
            trace("ERROR: Component type is already being added to this Entity: " + name);
            return;
        }
        if (!addedComponents.keys().hasNext()) {
            myWorld.registerEntityForAddFlush(this);
        }
        addedComponents[name] = component;
    }

    /**
     * Get a Component of this Entity by its Type.
     * @param componentT
     * @return Component or `null` if no component of this type could be found
     */
    public function getComponent<T:Component>(componentT:Class<T>):T {
        var name = Type.getClassName(componentT);
        var c:T = cast components[name];
        return c;
    }

    /**
     * Whether there is a Component of the specified Type present
     * @param componentT
     * @return Bool
     */
    public inline function hasComponent<T:Component>(componentT:Class<T>):Bool {
        var name = Type.getClassName(componentT);
        return components.exists(name);
    }

    /**
     * Remove a Component from this Entity
     * @param componentT
     */
    public inline function removeComponent<T:Component>(componentT:Class<T>) {
        var name = Type.getClassName(componentT);
        if (!hasComponent(componentT)) {
            trace("ERROR: Component type not present in this Entity: " + name);
            return;
        }
        if (droppedComponents.length == 0) {
            myWorld.registerEntityForRemoveFlush(this);
        }
        droppedComponents.push(name);
    }

    // Deferred component updates

    private inline function getPostRemovalComponentTypes():Array<String> {
        var arr = [for (c in components.keys()) c];
        for (c in droppedComponents) {
            arr.remove(c);
        }
        return arr;
    }

    private inline function getPostAdditionComponentTypes():Array<String> {
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
            removeComponent(Type.resolveClass(c));
        }
    }

    public inline function toString():String {
        var name = myWorld.entityName[this];
        var description = "Entity(" + name + ") {\n";
        for (component in components) {
            description = description + "  " + component + "\n";
        }
        description = description + "}";
        return description;
    }
}
