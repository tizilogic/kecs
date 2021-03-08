package kecs;

import kecs.Entity;


/**
 * Interface representing a filter to match against `kecs.Component` types and
 * sub-filters.
 */
interface Filter {
    private var myComponentTypes:Array<ClassKey>;
    private var myFilters:Array<Filter>;

    public function eval(componentTypes:Array<ClassKey>):Bool;
}


class FilterFactory {
    /**
     * Creates a filter that matches entities that contain all of the specified
     * `kecs.Component` types and match all sub-filters.
     * @param componentTypes Optional Array of Component Types
     * @param filters
     * @return Filter
     */
    public static function andFilter<T:Component>(?componentTypes:Array<ClassKey>, ?filters:Array<Filter>):Filter {
        if (componentTypes == null && filters == null) {
            throw "At least one parameter has to be passed in.";
        }
        return new _AndFilter(componentTypes, filters);
    }

    /**
     * Creates a filter that matches entities that contain at least one of the
     * specified `kecs.Component` types or match at least one sub-filter.
     * @param componentTypes
     * @param filters
     * @return Filter
     */
    public static function orFilter<T:Component>(?componentTypes:Array<ClassKey>, ?filters:Array<Filter>):Filter {
        if (componentTypes == null && filters == null) {
            throw "At least one parameter has to be passed in.";
        }
        return new _OrFilter(componentTypes, filters);
    }
}


@:dox(hide)
class _BaseFilter implements Filter {
    private var myComponentTypes:Array<ClassKey>;
    private var myFilters:Array<Filter>;

    public function new(?componentTypes:Array<ClassKey>, ?filters:Array<Filter>) {
        myComponentTypes = componentTypes != null ? componentTypes : [];
        myFilters = filters != null ? filters : [];
    }

    public function eval(componentTypes:Array<ClassKey>):Bool {
        throw "_BaseFilter is not meant to be used directly";
    }
}

@:dox(hide)
class _AndFilter extends _BaseFilter {
    public override function eval(componentTypes:Array<ClassKey>):Bool {
        for (cT in myComponentTypes) {
            if (componentTypes.indexOf(cT) == -1) {
                return false;
            }
        }
        for (f in myFilters) {
            if (!f.eval(componentTypes)) {
                return false;
            }
        }
        return true;
    }
}


@:dox(hide)
class _OrFilter extends _BaseFilter {
    public override function eval(componentTypes:Array<ClassKey>):Bool {
        for (cT in myComponentTypes) {
            if (componentTypes.indexOf(cT) != -1) {
                return true;
            }
        }
        for (f in myFilters) {
            if (f.eval(componentTypes)) {
                return true;
            }
        }
        return false;
    }
}
