with Ada.Containers;

separate (Awk_CLI.Options)
function Parse (Arguments : String_Vectors.Vector) return Parse_Result is
   use type Ada.Containers.Count_Type;

   Result       : Parsed_Options;
   Index        : Positive := 1;
   Stop_Options : Boolean := False;

   function Arg (Position : Positive) return String is
     (U.To_String (Arguments.Element (Position)));

   procedure Add_Operand (Text : String; Original_Index : Positive) is
   begin
      Result.Operands.Append
        (Operand'(Text => U.To_Unbounded_String (Text), Original_Index => Original_Index));
   end Add_Operand;

   procedure Add_V (Text : String; Original_Index : Positive) is
      Name  : U.Unbounded_String;
      Value : U.Unbounded_String;
   begin
      Split_Assignment (Text, Name, Value);
      Result.Initial_Assignments.Append
        (Assignment'(Name => Name, Value => Value, Original_Index => Original_Index,
                     Original_Text => U.To_Unbounded_String (Text)));
   end Add_V;

   function Missing_Program return Parse_Result is
     (Ok => False,
      Color => Result.Color,
      Diagnostic =>
        D.Make ("awk.usage.missing_program", D.Error, D.Usage,
                Hint_Id => "awk.hint.use_help"));

   function Invalid_Assignment (Text : String) return Parse_Result is
     (Ok => False,
      Color => Result.Color,
      Diagnostic =>
        D.Make ("awk.usage.invalid_assignment", D.Error, D.Usage,
                Name => "assignment", Value => Text,
                Hint_Id => "awk.hint.use_help"));

   function Invalid_Color (Value : String) return Parse_Result is
     (Ok => False,
      Color => Result.Color,
      Diagnostic =>
        D.Make ("awk.usage.invalid_color_mode", D.Error, D.Usage,
                Name => "value", Value => Value,
                Hint_Id => "awk.hint.use_help"));

   function Stdin_Program_File (Option : String) return Parse_Result is
     (Ok => False,
      Color => Result.Color,
      Diagnostic =>
        D.Make ("awk.usage.program_file_stdin_unsupported", D.Error, D.Usage,
                Name => "option", Value => Option,
                Hint_Id => "awk.hint.option_terminator"));

   function Unknown_Option (Option : String) return Parse_Result is
     (Ok => False,
      Color => Result.Color,
      Diagnostic =>
        D.Make ("awk.usage.unknown_option", D.Error, D.Usage,
                Name => "option", Value => Option,
                Hint_Id => "awk.hint.use_help"));

   function Has_Missing_Value return Boolean is
     (Index = Positive (Arguments.Length));
begin
   if Arguments.Is_Empty then
      return Missing_Program;
   end if;

   while Index <= Positive (Arguments.Length) loop
      declare
         Current : constant String := Arg (Index);
      begin
         if Stop_Options
           or else Current = ""
           or else Current (Current'First) /= '-'
           or else Current = "-"
         then
            Add_Operand (Current, Index);
            Stop_Options := True;
         elsif Current = "--" then
            Stop_Options := True;
         elsif Current = "--help" then
            Result.Help_Requested := True;
         elsif Current = "--version" then
            Result.Version_Requested := True;
         elsif Starts_With (Current, "--color=") then
            declare
               Value : constant String := Current (Current'First + 8 .. Current'Last);
            begin
               if Value = "auto" then
                  Result.Color := Color_Auto;
               elsif Value = "always" then
                  Result.Color := Color_Always;
               elsif Value = "never" then
                  Result.Color := Color_Never;
               else
                  return Invalid_Color (Value);
               end if;
            end;
         elsif Current = "-F" then
            if Has_Missing_Value then
               return Missing ("-F", Result.Color);
            end if;
            Index := Index + 1;
            Result.Has_Field_Separator := True;
            Result.Field_Separator := U.To_Unbounded_String (Arg (Index));
         elsif Starts_With (Current, "-F") then
            Result.Has_Field_Separator := True;
            Result.Field_Separator :=
              U.To_Unbounded_String (Current (Current'First + 2 .. Current'Last));
         elsif Current = "-v" then
            if Has_Missing_Value then
               return Missing ("-v", Result.Color);
            end if;
            Index := Index + 1;
            if not Is_Assignment_Text (Arg (Index)) then
               return Invalid_Assignment (Arg (Index));
            end if;
            Add_V (Arg (Index), Index);
         elsif Starts_With (Current, "-v") then
            declare
               Text : constant String := Current (Current'First + 2 .. Current'Last);
            begin
               if not Is_Assignment_Text (Text) then
                  return Invalid_Assignment (Text);
               end if;
               Add_V (Text, Index);
            end;
         elsif Current = "-f" then
            if Has_Missing_Value then
               return Missing ("-f", Result.Color);
            end if;
            Index := Index + 1;
            if Arg (Index) = "-" then
               return Stdin_Program_File ("-f -");
            end if;
            Result.Program_Files.Append
              (Program_File'(Name => U.To_Unbounded_String (Arg (Index)),
                             Original_Index => Index));
         elsif Starts_With (Current, "-f") then
            declare
               Name : constant String := Current (Current'First + 2 .. Current'Last);
            begin
               if Name = "-" then
                  return Stdin_Program_File ("-f-");
               end if;
               Result.Program_Files.Append
                 (Program_File'(Name => U.To_Unbounded_String (Name),
                                Original_Index => Index));
            end;
         else
            return Unknown_Option (Current);
         end if;
      end;
      Index := Index + 1;
   end loop;

   if not Result.Help_Requested
     and then not Result.Version_Requested
     and then Result.Program_Files.Is_Empty
     and then Result.Operands.Is_Empty
   then
      return Missing_Program;
   end if;

   return (Ok => True, Options => Result);
end Parse;
