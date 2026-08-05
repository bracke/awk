with AUnit.Assertions;

with Ada.Strings.Unbounded;

with Awk_CLI.Redirections;

package body Awk_Tests.Redirections.Materialize_Cases is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;

   LF : constant String := [1 => ASCII.LF];

   Materialize_Log : U.Unbounded_String;

   function Logging_Write
     (Path    : String;
      Content : String;
      Append  : Boolean) return Awk_CLI.Redirections.Write_Status
   is
   begin
      if Path = "blocked.txt" then
         return Awk_CLI.Redirections.Write_Failed;
      end if;

      U.Append (Materialize_Log, Path);
      U.Append (Materialize_Log, ":");
      U.Append (Materialize_Log, (if Append then "append" else "write"));
      U.Append (Materialize_Log, ":");
      U.Append (Materialize_Log, Content);
      return Awk_CLI.Redirections.Write_Success;
   end Logging_Write;

   procedure Test_Materialize_Order_And_Append
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Outputs : Awk_CLI.Redirections.Redirection_Vectors.Vector;
   begin
      Materialize_Log := U.Null_Unbounded_String;
      Outputs.Append
        (Awk_CLI.Redirections.Redirected_Output'
           (Path => U.To_Unbounded_String ("a.txt"),
            Content => U.To_Unbounded_String ("one" & LF),
            Append => False));
      Outputs.Append
        (Awk_CLI.Redirections.Redirected_Output'
           (Path => U.To_Unbounded_String ("a.txt"),
            Content => U.To_Unbounded_String ("two" & LF),
            Append => True));
      Outputs.Append
        (Awk_CLI.Redirections.Redirected_Output'
           (Path => U.To_Unbounded_String ("b.txt"),
            Content => U.Null_Unbounded_String,
            Append => True));

      declare
         Result : constant Awk_CLI.Redirections.Materialize_Result :=
           Awk_CLI.Redirections.Materialize (Outputs, Logging_Write'Access);
      begin
         Assert (Result.Ok, "redirection materialization succeeds");
         Assert
           (U.To_String (Materialize_Log) =
            "a.txt:write:one" & LF &
            "a.txt:append:two" & LF &
            "b.txt:append:",
            "materializer preserves order, append intent, and exact content");
      end;
   end Test_Materialize_Order_And_Append;

   procedure Test_Materialize_Stops_On_First_Failure
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Outputs : Awk_CLI.Redirections.Redirection_Vectors.Vector;
   begin
      Materialize_Log := U.Null_Unbounded_String;
      Outputs.Append
        (Awk_CLI.Redirections.Redirected_Output'
           (Path => U.To_Unbounded_String ("ok.txt"),
            Content => U.To_Unbounded_String ("ok" & LF),
            Append => False));
      Outputs.Append
        (Awk_CLI.Redirections.Redirected_Output'
           (Path => U.To_Unbounded_String ("blocked.txt"),
            Content => U.To_Unbounded_String ("blocked" & LF),
            Append => False));
      Outputs.Append
        (Awk_CLI.Redirections.Redirected_Output'
           (Path => U.To_Unbounded_String ("later.txt"),
            Content => U.To_Unbounded_String ("later" & LF),
            Append => False));

      declare
         Result : constant Awk_CLI.Redirections.Materialize_Result :=
           Awk_CLI.Redirections.Materialize (Outputs, Logging_Write'Access);
      begin
         Assert (not Result.Ok, "failed redirection materialization is reported");
         Assert
           (U.To_String (Result.Diagnostic.Message_Id) = "awk.output_file.write_failed",
            "write failure diagnostic is retained");
         Assert
           (U.To_String (Materialize_Log) = "ok.txt:write:ok" & LF,
            "materializer stops before writes after the first failure");
      end;
   end Test_Materialize_Stops_On_First_Failure;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Materialize_Order_And_Append'Access,
         "materialize order and append");
      Registration.Register_Routine
        (T, Test_Materialize_Stops_On_First_Failure'Access,
         "materialize stops on first failure");
   end Register;

end Awk_Tests.Redirections.Materialize_Cases;
