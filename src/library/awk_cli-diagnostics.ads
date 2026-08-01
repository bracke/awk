with Ada.Strings.Unbounded;

package Awk_CLI.Diagnostics is
   package U renames Ada.Strings.Unbounded;

   type Diagnostic_Severity is
     (Information, Warning, Error, Internal_Error);

   type Diagnostic_Category is
     (Usage, Program_Source, Input, Output, Interpreter, Environment, Platform, Internal);

   type Exit_Code is range 0 .. 255;
   Success_Exit      : constant Exit_Code := 0;
   Interpreter_Exit  : constant Exit_Code := 1;
   Usage_Exit        : constant Exit_Code := 2;
   IO_Exit           : constant Exit_Code := 3;
   Internal_Exit     : constant Exit_Code := 70;

   type Diagnostic is record
      Message_Id       : U.Unbounded_String;
      Severity         : Diagnostic_Severity := Error;
      Category         : Diagnostic_Category := Usage;
      Name             : U.Unbounded_String;
      Value            : U.Unbounded_String;
      Detail           : U.Unbounded_String;
      Hint_Id          : U.Unbounded_String;
      Source_Name      : U.Unbounded_String;
      Line             : Natural := 0;
      Column           : Natural := 0;
   end record;

   function Make
     (Message_Id : String;
      Severity   : Diagnostic_Severity;
      Category   : Diagnostic_Category;
      Name       : String := "";
      Value      : String := "";
      Detail     : String := "";
      Hint_Id    : String := "") return Diagnostic;

   function Escape (Text : String) return String;
   function Status_For (Item : Diagnostic) return Exit_Code;
end Awk_CLI.Diagnostics;
