package kecs;

import kecs.Entity;
import kecs.Filter;
import kecs.World;


/**
 * A system implements functionality that is executed during an update call to
 * the `kecs.World` it is registered with.
 *
 * A system has one or more filters that test whether the system should process
 * an entity during an update. It also implements the functionality to set up
 * and tear down the entity when it enters or leaves filters through the means
 * of Reflection. If the derived class contains functions beginning with
 * `enterFilter`/`exitFilter` and ending with the filters' name, those functions
 * will be called for every `kecs.Entity` that is added or removed and matches
 * that `kecs.Filter`.
 */
@:allow(kecs.World)
class System {
    private var myWorld:World;
    private var myFilters:Map<String, Filter>;
    private var myEntities:Map<Filter, Array<Entity>>;
    private var myAllEntities:Array<Entity>;

    public function new() {
        myEntities = [];
        myAllEntities = [];
    }

    /**
     * The system's functionality that is run during an update. This function
     * has to be overridden by the derived class, otherwise this will throw an
     * Exception.
     */
    public function update() {
        throw "This function must be overridden by the derived class";
    }

    private function enterFilters(filters:Array<String>, entity:Entity) {
        for (filter in filters) {
            for (field in Type.getInstanceFields(Type.getClass(this))) {
                if (field == "enterFilter" + filter) {
                    Reflect.callMethod(this, Reflect.field(this, field), [entity]);
                }
            }
        }
    }

    private function exitFilters(filters:Array<String>, entity:Entity) {
        for (filter in filters) {
            for (field in Type.getInstanceFields(Type.getClass(this))) {
                if (field == "exitFilter" + filter) {
                    Reflect.callMethod(this, Reflect.field(this, field), [entity]);
                }
            }
        }
    }

    private inline function proposeAdd(entity:Entity) {
        var enteredFilters:Array<String> = [];
        var futureComponents = entity.getPostAdditionComponentTypes();
        for (kv in myFilters.keyValueIterator()) {
            var match = kv.value.eval(futureComponents);
            var present = false;
            if (!myEntities.exists(kv.value)) {
                myEntities[kv.value] = [];
            }
            else if (myEntities[kv.value].contains(entity)) {
                present = true;
            }
            if (match && !present) {
                myEntities[kv.value].push(entity);
                enteredFilters.push(kv.key);
            }
        }
        enterFilters(enteredFilters, entity);
        if (!myAllEntities.contains(entity)) {
            myAllEntities.push(entity);
        }
    }

    private inline function proposeRemoval(entity:Entity) {
        var exitedFilters:Array<String> = [];
        var futureComponents = entity.getPostRemovalComponentTypes();
        for (kv in myFilters.keyValueIterator()) {
            var match = kv.value.eval(futureComponents);
            var present = myEntities[kv.value].contains(entity);
            if (match && !present) {
                myEntities[kv.value].remove(entity);
                exitedFilters.push(kv.key);
            }
        }
        exitFilters(exitedFilters, entity);
        myAllEntities.remove(entity);
    }

    private inline function destroy() {
        for (entity in myAllEntities) {
            var filters:Array<String> = [];
            for (kv in myFilters.keyValueIterator()) {
                if (myEntities[kv.value].contains(entity)) {
                    filters.push(kv.key);
                }
            }
            exitFilters(filters, entity);
        }
        myFilters.clear();
        myEntities.clear();
    }

    public function toString():String {
        return Type.getClassName(Type.getClass(this));
    }
}
