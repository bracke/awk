with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Awk_CLI is
   --  Testable top-level runner for the awk executable.
   --
   --  This package is internal CLI infrastructure. It is public only so the
   --  executable and AUnit harness can exercise the same code path; it is not
   --  a stable reusable library API.

   type Exit_Code is range 0 .. 255;

   type Invocation_Context is tagged limited private;
   --  Complete host invocation model used by the runner.

   procedure Initialize_From_Process (Context : in out Invocation_Context);
   --  Populate Context from the real process arguments, environment, locale,
   --  standard streams, and terminal state.

   procedure Clear (Context : in out Invocation_Context);
   --  Reset Context to an empty deterministic in-memory invocation.

   procedure Add_Argument (Context : in out Invocation_Context; Value : String);
   --  Append one raw command-line argument for in-memory tests.

   procedure Set_Standard_Input (Context : in out Invocation_Context; Value : String);
   --  Set the complete standard-input text for in-memory execution.

   procedure Set_Locale (Context : in out Invocation_Context; Value : String);
   --  Set the locale name used for CLI-owned localized text.

   procedure Set_Catalog_Path (Context : in out Invocation_Context; Value : String);
   --  Set the message catalog path used by this invocation.

   procedure Add_File
     (Context : in out Invocation_Context;
      Path    : String;
      Content : String;
      Readable : Boolean := True;
      Writable : Boolean := True;
      Openable : Boolean := True);
   --  Add or replace an in-memory virtual file and its simulated I/O policy.

   procedure Add_Command_Output
     (Context : in out Invocation_Context;
      Command : String;
      Output  : String);
   --  Register deterministic output for command getline integration tests.

   procedure Add_Environment
     (Context : in out Invocation_Context;
      Name    : String;
      Value   : String);
   --  Add one environment entry for ENVIRON construction.

   procedure Fail_Standard_Output (Context : in out Invocation_Context; Enabled : Boolean);
   --  Enable or disable simulated standard-output write failure.

   procedure Fail_Standard_Error (Context : in out Invocation_Context; Enabled : Boolean);
   --  Enable or disable simulated standard-error write failure.

   procedure Fail_Standard_Input (Context : in out Invocation_Context; Enabled : Boolean);
   --  Enable or disable simulated standard-input read failure.

   procedure Set_Standard_Output_Terminal (Context : in out Invocation_Context; Enabled : Boolean);
   --  Set terminal detection for standard output in this invocation.

   procedure Set_Standard_Error_Terminal (Context : in out Invocation_Context; Enabled : Boolean);
   --  Set terminal detection for standard error in this invocation.

   function Run (Context : in out Invocation_Context) return Exit_Code;
   --  Execute one complete CLI invocation and return the process exit code.

   function Standard_Output (Context : Invocation_Context) return String;
   --  Return captured standard output from the last in-memory run.

   function Standard_Error (Context : Invocation_Context) return String;
   --  Return captured standard error from the last in-memory run.

   function Has_Diagnostic (Context : Invocation_Context) return Boolean;
   --  Return whether the last run recorded a structured diagnostic.

   function Last_Diagnostic_Message_Id (Context : Invocation_Context) return String;
   --  Return the stable message ID of the last diagnostic, if any.

   function Last_Diagnostic_Category (Context : Invocation_Context) return String;
   --  Return the category name of the last diagnostic, if any.

   function Last_Diagnostic_Severity (Context : Invocation_Context) return String;
   --  Return the severity name of the last diagnostic, if any.

   function Written_File_Count (Context : Invocation_Context) return Natural;
   --  Return the number of captured virtual file write operations.

   function Written_File_Name (Context : Invocation_Context; Index : Positive) return String;
   --  Return the path for captured write operation Index.

   function Written_File_Content (Context : Invocation_Context; Index : Positive) return String;
   --  Return the exact content for captured write operation Index.

   function Written_File_Append (Context : Invocation_Context; Index : Positive) return Boolean;
   --  Return whether captured write operation Index used append semantics.

private
   package U renames Ada.Strings.Unbounded;

   type Virtual_File is record
      Path     : U.Unbounded_String;
      Content  : U.Unbounded_String;
      Readable : Boolean := True;
      Writable : Boolean := True;
      Openable : Boolean := True;
   end record;

   type Env_Item is record
      Name  : U.Unbounded_String;
      Value : U.Unbounded_String;
   end record;

   type Write_Operation is record
      Path    : U.Unbounded_String;
      Content : U.Unbounded_String;
      Append  : Boolean := False;
   end record;

   type Command_Output is record
      Command : U.Unbounded_String;
      Output  : U.Unbounded_String;
   end record;

   package File_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Virtual_File);
   package String_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => U.Unbounded_String, "=" => U."=");
   package Env_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Env_Item);
   package Write_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Write_Operation);
   package Command_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Command_Output);

   type Invocation_Context is tagged limited record
      Arguments    : String_Vectors.Vector;
      Standard_In  : U.Unbounded_String;
      Locale       : U.Unbounded_String := U.To_Unbounded_String ("en");
      Catalog_Path : U.Unbounded_String := U.To_Unbounded_String ("resources/messages/catalog.txt");
      Files        : File_Vectors.Vector;
      Commands     : Command_Vectors.Vector;
      Environment  : Env_Vectors.Vector;
      Standard_Out : U.Unbounded_String;
      Standard_Err : U.Unbounded_String;
      Diagnostic_Set : Boolean := False;
      Diagnostic_Id       : U.Unbounded_String;
      Diagnostic_Category : U.Unbounded_String;
      Diagnostic_Severity : U.Unbounded_String;
      Writes       : Write_Vectors.Vector;
      Use_Process  : Boolean := False;
      Stdin_Fails  : Boolean := False;
      Stdout_Fails : Boolean := False;
      Stderr_Fails : Boolean := False;
      Stdout_Terminal : Boolean := False;
      Stderr_Terminal : Boolean := False;
   end record;
end Awk_CLI;
