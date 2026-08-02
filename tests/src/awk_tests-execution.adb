with AUnit.Assertions;

with Ada.Strings.Unbounded;

with System;
with System.Address_To_Access_Conversions;

with Awk_CLI.Environment;
with Awk_CLI.Execution;
with Awk_CLI.Inputs;
with Awk_CLI.Operands;
with Awk_CLI.Options;
with Awk_CLI.Platform;
with Awk_CLI.Programs;
with Awk_CLI.Redirections;

package body Awk_Tests.Execution is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   package Opt renames Awk_CLI.Options;

   LF : constant String := [1 => ASCII.LF];

   type Live_State is record
      Output          : U.Unbounded_String;
      Redirection_Log : U.Unbounded_String;
      Fail_Output     : Boolean := False;
      Fail_Redirect   : Boolean := False;
   end record;

   package Live_State_Access is new System.Address_To_Access_Conversions (Live_State);

   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk execution");
   end Name;

   function Read_Test_File
     (Path : String;
      Content : out U.Unbounded_String) return Awk_CLI.Platform.Read_Status
   is
   begin
      if Path = "input" then
         Content := U.To_Unbounded_String ("x y" & LF);
         return Awk_CLI.Platform.Read_Success;
      else
         Content := U.Null_Unbounded_String;
         return Awk_CLI.Platform.Open_Failed;
      end if;
   end Read_Test_File;

   function Live_Output
     (User_Data : System.Address;
      Content   : String) return Boolean
   is
      State : constant Live_State_Access.Object_Pointer :=
        Live_State_Access.To_Pointer (User_Data);
   begin
      if State.Fail_Output then
         return False;
      end if;
      U.Append (State.Output, Content);
      return True;
   end Live_Output;

   function Live_Redirection
     (User_Data : System.Address;
      Path      : String;
      Content   : String;
      Append    : Boolean) return Awk_CLI.Redirections.Write_Status
   is
      State : constant Live_State_Access.Object_Pointer :=
        Live_State_Access.To_Pointer (User_Data);
   begin
      if State.Fail_Redirect then
         return Awk_CLI.Redirections.Write_Failed;
      end if;
      U.Append (State.Redirection_Log, Path);
      U.Append (State.Redirection_Log, ":");
      U.Append (State.Redirection_Log, (if Append then "append" else "write"));
      U.Append (State.Redirection_Log, ":");
      U.Append (State.Redirection_Log, Content);
      return Awk_CLI.Redirections.Write_Success;
   end Live_Redirection;

   procedure Test_Execution (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : Opt.String_Vectors.Vector;
      Env    : Awk_CLI.Environment.Entry_Vectors.Vector;
   begin
      Args.Append (U.To_Unbounded_String ("-vX=7"));
      Args.Append (U.To_Unbounded_String ("BEGIN { print X + 1 }"));
      declare
         Parsed : constant Opt.Parse_Result := Opt.Parse (Args);
         Source : constant Awk_CLI.Programs.Resolve_Result :=
           Awk_CLI.Programs.Resolve (Parsed.Options, Read_Test_File'Access);
         Ops    : constant Awk_CLI.Operands.Operand_Vectors.Vector :=
           Awk_CLI.Operands.Classify (Source.Source.Operands);
         Input  : constant Awk_CLI.Inputs.Load_Result :=
           Awk_CLI.Inputs.Load (Ops, "", Read_Test_File'Access);
         Exec   : constant Awk_CLI.Execution.Execution_Result :=
           Awk_CLI.Execution.Execute
             (U.To_String (Source.Source.Text), Parsed.Options, Ops, Input.Files, Env);
      begin
         Assert (Exec.Ok, "execution succeeds");
         Assert (U.To_String (Exec.Standard_Output) = "8" & LF, "-v visible before BEGIN");
         Assert (Awk_CLI.Execution.Supports_Streaming_Execution,
                 "execution adapter exposes live awklib input callbacks");
      end;
   end Test_Execution;

   procedure Test_Execution_Live_Callbacks (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : Opt.String_Vectors.Vector;
      Env    : Awk_CLI.Environment.Entry_Vectors.Vector;
      State  : aliased Live_State;
   begin
      Args.Append
        (U.To_Unbounded_String
           ("{ print $2; print ""saved"" > ""out.txt""; print ""again"" >> ""out.txt"" }"));
      declare
         Parsed : constant Opt.Parse_Result := Opt.Parse (Args);
         Source : constant Awk_CLI.Programs.Resolve_Result :=
           Awk_CLI.Programs.Resolve (Parsed.Options, Read_Test_File'Access);
         Ops    : constant Awk_CLI.Operands.Operand_Vectors.Vector :=
           Awk_CLI.Operands.Classify (Source.Source.Operands);
         Input  : constant Awk_CLI.Inputs.Load_Result :=
           Awk_CLI.Inputs.Load (Ops, "one two" & LF, Read_Test_File'Access);
         Exec   : constant Awk_CLI.Execution.Execution_Result :=
           Awk_CLI.Execution.Execute_Live
             (U.To_String (Source.Source.Text),
              Parsed.Options, Ops, Input.Files, Env,
              Live_Output'Access, Live_Redirection'Access,
              User_Data => State'Address);
      begin
         Assert (Exec.Ok, "live execution succeeds");
         Assert (U.To_String (Exec.Standard_Output) = "",
                 "live stdout is not captured in execution result");
         Assert (Exec.Redirections.Is_Empty,
                 "live redirection writes are not captured in execution result");
         Assert (U.To_String (State.Output) = "two" & LF,
                 "live stdout callback receives AWK output exactly");
         Assert
           (U.To_String (State.Redirection_Log) =
            "out.txt:write:saved" & LF & "out.txt:append:again" & LF,
            "live redirection callback receives append mode and content");
      end;
   end Test_Execution_Live_Callbacks;

   procedure Test_Execution_Live_Output_Failure
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : Opt.String_Vectors.Vector;
      Env    : Awk_CLI.Environment.Entry_Vectors.Vector;
      State  : aliased Live_State :=
        (Output => U.Null_Unbounded_String,
         Redirection_Log => U.Null_Unbounded_String,
         Fail_Output => True,
         Fail_Redirect => False);
   begin
      Args.Append (U.To_Unbounded_String ("BEGIN { print ""x"" }"));
      declare
         Parsed : constant Opt.Parse_Result := Opt.Parse (Args);
         Source : constant Awk_CLI.Programs.Resolve_Result :=
           Awk_CLI.Programs.Resolve (Parsed.Options, Read_Test_File'Access);
         Ops    : constant Awk_CLI.Operands.Operand_Vectors.Vector :=
           Awk_CLI.Operands.Classify (Source.Source.Operands);
         Input  : constant Awk_CLI.Inputs.Load_Result :=
           Awk_CLI.Inputs.Load (Ops, "", Read_Test_File'Access);
         Exec   : constant Awk_CLI.Execution.Execution_Result :=
           Awk_CLI.Execution.Execute_Live
             (U.To_String (Source.Source.Text),
              Parsed.Options, Ops, Input.Files, Env,
              Live_Output'Access, Live_Redirection'Access,
              User_Data => State'Address);
      begin
         Assert (not Exec.Ok, "live stdout failure is reported");
         Assert
           (U.To_String (Exec.Diagnostic.Message_Id) = "awk.standard_output.write_failed",
            "live stdout failure uses standard output diagnostic");
      end;
   end Test_Execution_Live_Output_Failure;

   overriding procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Execution'Access, "awklib execution adapter");
      Registration.Register_Routine
        (T, Test_Execution_Live_Callbacks'Access,
         "awklib live execution callbacks");
      Registration.Register_Routine
        (T, Test_Execution_Live_Output_Failure'Access,
         "awklib live stdout failure");
   end Register_Tests;
end Awk_Tests.Execution;
