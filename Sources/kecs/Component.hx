package kecs;


/**
 * The `Component` is simply an empty class with an empty constructor to leave
 * the implementation up to the needs of the user. A `Component` usually is a
 * container holding data, which is updated/modified by a `kecs.System`.
 */
class Component {
    public function new() {}

    public function toString():String {
        var instanceFields = Type.getInstanceFields(Type.getClass(this));
        var name = Type.getClassName(Type.getClass(this));
        var description = name + " {\n";
        for (field in instanceFields) {
            switch (field) {
                case "toString":
                default:
                    var value = Reflect.field(this, field);
                    if (value != null) {
                        description = description + "  " + field + ": " + value + "\n";
                    }
            }
        }
        description = description + "}";
        return description;
    }
}
