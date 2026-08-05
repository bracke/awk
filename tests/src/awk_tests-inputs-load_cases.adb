with AUnit.Assertions;

with Ada.Containers;
with Ada.Strings.Unbounded;

with Awk_CLI.Inputs;
with Awk_CLI.Operands;
with Awk_CLI.Options;
with Awk_CLI.Platform;

package body Awk_Tests.Inputs.Load_Cases is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   package Opt renames Awk_CLI.Options;

   LF : constant String := [1 => ASCII.LF];
   use type Ada.Containers.Count_Type;

   Read_Count : Natural := 0;

   function Read_Load_Test_File
     (Path    : String;
      Content : out U.Unbounded_String) return Awk_CLI.Platform.Read_Status
   is
   begin
      Read_Count := Read_Count + 1;
      if Path = "file.txt" then
         Content := U.To_Unbounded_String ("file" & LF);
         return Awk_CLI.Platform.Read_Success;
      else
         Content := U.Null_Unbounded_String;
         return Awk_CLI.Platform.Open_Failed;
      end if;
   end Read_Load_Test_File;

   procedure Test_Load_Interspersed_Assignments_And_Stdin
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Raw : Opt.Operand_Vectors.Vector;
   begin
      Read_Count := 0;
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("A=1"), Original_Index => 2));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("-"), Original_Index => 3));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("file.txt"), Original_Index => 4));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("B=2"), Original_Index => 5));
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("-"), Original_Index => 6));

      declare
         Classified : constant Awk_CLI.Operands.Operand_Vectors.Vector :=
           Awk_CLI.Operands.Classify (Raw);
         Loaded : constant Awk_CLI.Inputs.Load_Result :=
           Awk_CLI.Inputs.Load
             (Classified, "stdin" & LF, Read_Load_Test_File'Access);
      begin
         Assert (Loaded.Ok, "interspersed assignment input load succeeds");
         Assert (Loaded.Files.Length = 3,
                 "runtime assignments are not materialized as input streams");
         Assert (Read_Count = 1, "runtime assignments do not trigger file reads");
         Assert (U.To_String (Loaded.Files.Element (1).Name) = "-",
                 "first explicit stdin is retained");
         Assert (U.To_String (Loaded.Files.Element (1).Content) = "stdin" & LF,
                 "first explicit stdin consumes data");
         Assert (U.To_String (Loaded.Files.Element (2).Name) = "file.txt",
                 "named file remains ordered between stdin operands");
         Assert (U.To_String (Loaded.Files.Element (2).Content) = "file" & LF,
                 "named file content is loaded");
         Assert (U.To_String (Loaded.Files.Element (3).Name) = "-",
                 "second explicit stdin is retained");
         Assert (U.To_String (Loaded.Files.Element (3).Content) = "",
                 "second explicit stdin observes EOF");
      end;
   end Test_Load_Interspersed_Assignments_And_Stdin;

   procedure Test_Load_Assignment_Only_Implicit_Stdin
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Raw : Opt.Operand_Vectors.Vector;
   begin
      Read_Count := 0;
      Raw.Append (Opt.Operand'(Text => U.To_Unbounded_String ("Only=assignment"), Original_Index => 2));

      declare
         Classified : constant Awk_CLI.Operands.Operand_Vectors.Vector :=
           Awk_CLI.Operands.Classify (Raw);
         Loaded : constant Awk_CLI.Inputs.Load_Result :=
           Awk_CLI.Inputs.Load
             (Classified, "implicit" & LF, Read_Load_Test_File'Access);
      begin
         Assert (Loaded.Ok, "assignment-only input load succeeds");
         Assert (Loaded.Files.Length = 1, "implicit stdin stream is added");
         Assert (Read_Count = 0, "assignment-only operands do not read files");
         Assert (U.To_String (Loaded.Files.Element (1).Name) = "",
                 "implicit stdin has empty awklib filename");
         Assert (U.To_String (Loaded.Files.Element (1).Content) = "implicit" & LF,
                 "implicit stdin content is loaded");
      end;
   end Test_Load_Assignment_Only_Implicit_Stdin;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Load_Interspersed_Assignments_And_Stdin'Access,
         "load interspersed assignments and stdin");
      Registration.Register_Routine
        (T, Test_Load_Assignment_Only_Implicit_Stdin'Access,
         "load assignment-only implicit stdin");
   end Register;
end Awk_Tests.Inputs.Load_Cases;
