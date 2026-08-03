with AUnit.Assertions;

with Ada.Containers;
with Ada.Strings.Unbounded;

with Awk_CLI.Options;

package body Awk_Tests.CLI_Options.Operand_Cases is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   package Opt renames Awk_CLI.Options;

   use type Ada.Containers.Count_Type;
   use type Opt.Color_Mode;

   procedure Test_Option_Terminator_Treats_Long_Options_As_Operands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : Opt.String_Vectors.Vector;
   begin
      Args.Append (U.To_Unbounded_String ("--"));
      Args.Append (U.To_Unbounded_String ("--help"));
      Args.Append (U.To_Unbounded_String ("--version"));
      Args.Append (U.To_Unbounded_String ("--color=always"));
      declare
         Result : constant Opt.Parse_Result := Opt.Parse (Args);
      begin
         Assert (Result.Ok, "terminator parse succeeds");
         Assert (not Result.Options.Help_Requested,
                 "--help after -- is an operand, not a help request");
         Assert (not Result.Options.Version_Requested,
                 "--version after -- is an operand, not a version request");
         Assert (Result.Options.Color = Opt.Color_Auto,
                 "--color after -- does not change parser color policy");
         Assert (Result.Options.Operands.Length = 3,
                 "all long-option-looking arguments after -- are operands");
         Assert (U.To_String (Result.Options.Operands.Element (1).Text) = "--help",
                 "first operand after -- is preserved");
         Assert (Result.Options.Operands.Element (1).Original_Index = 2,
                 "first operand after -- keeps original index");
         Assert (U.To_String (Result.Options.Operands.Element (3).Text) = "--color=always",
                 "color-looking operand after -- is preserved");
      end;
   end Test_Option_Terminator_Treats_Long_Options_As_Operands;

   procedure Test_Options_After_Direct_Program_Are_Operands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : Opt.String_Vectors.Vector;
   begin
      Args.Append (U.To_Unbounded_String ("BEGIN { print ARGV[1] }"));
      Args.Append (U.To_Unbounded_String ("--version"));
      Args.Append (U.To_Unbounded_String ("--color=always"));
      Args.Append (U.To_Unbounded_String ("-F"));
      declare
         Result : constant Opt.Parse_Result := Opt.Parse (Args);
      begin
         Assert (Result.Ok, "post-program option-looking operands parse");
         Assert (not Result.Options.Version_Requested,
                 "--version after direct program is an operand");
         Assert (Result.Options.Color = Opt.Color_Auto,
                 "--color after direct program does not alter color policy");
         Assert (Result.Options.Operands.Length = 4,
                 "direct program and later option-looking operands are retained");
         Assert (U.To_String (Result.Options.Operands.Element (2).Text) = "--version",
                 "post-program --version spelling is preserved");
         Assert (Result.Options.Operands.Element (2).Original_Index = 2,
                 "post-program operand index is preserved");
         Assert (U.To_String (Result.Options.Operands.Element (4).Text) = "-F",
                 "post-program -F spelling is preserved as an operand");
      end;
   end Test_Options_After_Direct_Program_Are_Operands;

   procedure Test_Options_After_File_Mode_Operand_Are_Operands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : Opt.String_Vectors.Vector;
   begin
      Args.Append (U.To_Unbounded_String ("-f"));
      Args.Append (U.To_Unbounded_String ("program.awk"));
      Args.Append (U.To_Unbounded_String ("input.txt"));
      Args.Append (U.To_Unbounded_String ("-vX=late"));
      declare
         Result : constant Opt.Parse_Result := Opt.Parse (Args);
      begin
         Assert (Result.Ok, "post-input option-looking operands parse");
         Assert (Result.Options.Program_Files.Length = 1, "program file retained");
         Assert (Result.Options.Initial_Assignments.Is_Empty,
                 "-v after first file-mode operand is not an initial assignment");
         Assert (Result.Options.Operands.Length = 2,
                 "file-mode operand and later option-looking operand are retained");
         Assert (U.To_String (Result.Options.Operands.Element (2).Text) = "-vX=late",
                 "post-input option-looking argument spelling is preserved");
         Assert (Result.Options.Operands.Element (2).Original_Index = 4,
                 "post-input option-looking argument index is preserved");
      end;
   end Test_Options_After_File_Mode_Operand_Are_Operands;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Option_Terminator_Treats_Long_Options_As_Operands'Access,
         "option terminator long operands");
      Registration.Register_Routine
        (T, Test_Options_After_Direct_Program_Are_Operands'Access,
         "options after direct program are operands");
      Registration.Register_Routine
        (T, Test_Options_After_File_Mode_Operand_Are_Operands'Access,
         "options after file-mode operand are operands");
   end Register;
end Awk_Tests.CLI_Options.Operand_Cases;
