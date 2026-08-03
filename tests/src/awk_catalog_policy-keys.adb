with Ada.Strings.Unbounded;

package body Awk_Catalog_Policy.Keys is
   package U renames Ada.Strings.Unbounded;

   Required : constant array (Positive range <>) of U.Unbounded_String :=
     [U.To_Unbounded_String ("awk.help.title"),
      U.To_Unbounded_String ("awk.help.summary"),
      U.To_Unbounded_String ("awk.help.usage.direct_program"),
      U.To_Unbounded_String ("awk.help.usage.program_files"),
      U.To_Unbounded_String ("awk.help.options.field_separator"),
      U.To_Unbounded_String ("awk.help.options.variable"),
      U.To_Unbounded_String ("awk.help.options.program_file"),
      U.To_Unbounded_String ("awk.help.options.color"),
      U.To_Unbounded_String ("awk.help.options.help"),
      U.To_Unbounded_String ("awk.help.options.version"),
      U.To_Unbounded_String ("awk.help.options.terminator"),
      U.To_Unbounded_String ("awk.help.operands"),
      U.To_Unbounded_String ("awk.help.stdin"),
      U.To_Unbounded_String ("awk.help.exit_statuses"),
      U.To_Unbounded_String ("awk.help.compatibility.heading"),
      U.To_Unbounded_String ("awk.help.compatibility.awklib_limitations"),
      U.To_Unbounded_String ("awk.version.program"),
      U.To_Unbounded_String ("awk.version.interpreter"),
      U.To_Unbounded_String ("awk.version.license"),
      U.To_Unbounded_String ("awk.diagnostic.label.info"),
      U.To_Unbounded_String ("awk.diagnostic.label.error"),
      U.To_Unbounded_String ("awk.diagnostic.label.warning"),
      U.To_Unbounded_String ("awk.diagnostic.label.internal_error"),
      U.To_Unbounded_String ("awk.diagnostic.header"),
      U.To_Unbounded_String ("awk.diagnostic.source_location"),
      U.To_Unbounded_String ("awk.diagnostic.detail"),
      U.To_Unbounded_String ("awk.diagnostic.hint"),
      U.To_Unbounded_String ("awk.source.command_line"),
      U.To_Unbounded_String ("awk.usage.missing_program"),
      U.To_Unbounded_String ("awk.usage.unknown_option"),
      U.To_Unbounded_String ("awk.usage.missing_option_argument"),
      U.To_Unbounded_String ("awk.usage.invalid_assignment"),
      U.To_Unbounded_String ("awk.usage.invalid_color_mode"),
      U.To_Unbounded_String ("awk.usage.program_file_stdin_unsupported"),
      U.To_Unbounded_String ("awk.program_file.open_failed"),
      U.To_Unbounded_String ("awk.program_file.read_failed"),
      U.To_Unbounded_String ("awk.input_file.open_failed"),
      U.To_Unbounded_String ("awk.input_file.read_failed"),
      U.To_Unbounded_String ("awk.output_file.open_failed"),
      U.To_Unbounded_String ("awk.output_file.write_failed"),
      U.To_Unbounded_String ("awk.standard_input.read_failed"),
      U.To_Unbounded_String ("awk.standard_output.write_failed"),
      U.To_Unbounded_String ("awk.interpreter.parse_failed"),
      U.To_Unbounded_String ("awk.interpreter.runtime_failed"),
      U.To_Unbounded_String ("awk.interpreter.unsupported_operation"),
      U.To_Unbounded_String ("awk.internal.localization_failed"),
      U.To_Unbounded_String ("awk.internal.unexpected_exception"),
      U.To_Unbounded_String ("awk.hint.use_help"),
      U.To_Unbounded_String ("awk.hint.option_terminator")];

   function Count return Positive is
   begin
      return Required'Length;
   end Count;

   function Item (Index : Positive) return String is
   begin
      return U.To_String (Required (Index));
   end Item;

   function Contains (Key : String) return Boolean is
   begin
      for Candidate of Required loop
         if Key = U.To_String (Candidate) then
            return True;
         end if;
      end loop;
      return False;
   end Contains;
end Awk_Catalog_Policy.Keys;
