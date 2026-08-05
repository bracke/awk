package body Awk_CLI.Options is
   package D renames Awk_CLI.Diagnostics;

   function Starts_With (Text, Prefix : String) return Boolean is
     (Text'Length >= Prefix'Length
      and then Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix);

   function Missing (Option : String; Color : Color_Mode := Color_Auto) return Parse_Result is
     (Ok => False,
      Color => Color,
      Diagnostic =>
        D.Make ("awk.usage.missing_option_argument", D.Error, D.Usage,
                Name => "option", Value => Option, Hint_Id => "awk.hint.use_help"));

   function Is_Assignment_Text (Text : String) return Boolean is separate;

   procedure Split_Assignment (Text : String; Name, Value : out U.Unbounded_String) is separate;

   function Parse (Arguments : String_Vectors.Vector) return Parse_Result is separate;

end Awk_CLI.Options;
