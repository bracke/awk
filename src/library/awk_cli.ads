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

   --  @param Context Invocation context to populate from the process.
   procedure Initialize_From_Process (Context : in out Invocation_Context);

   --  @param Context Invocation context to reset.
   procedure Clear (Context : in out Invocation_Context);

   --  @param Context Invocation context to execute.
   --  @return Stable process exit code.
   function Run (Context : in out Invocation_Context) return Exit_Code;

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
      No_Color         : Boolean := False;
   end record;
end Awk_CLI;
