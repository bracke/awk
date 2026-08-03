with Awk_CLI.Redirections;

package Awk_CLI.Context_IO is
   --  Invocation-context I/O mutation helpers.
   --
   --  This child package owns captured stdout and virtual file write storage.
   --  AWK output content is forwarded exactly and never localized or styled.

   --  @param Context Invocation context to update.
   --  @param Content Exact standard-output content to write.
   --  @return True when output was accepted by the context and host.
   function Write_Standard_Output
     (Context : in out Invocation_Context;
      Content : String) return Boolean;
   --  Append exact AWK or CLI-owned standard output to Context and, when this
   --  is a process-backed invocation, write it to the host standard output.
   --  @param Context Invocation context to update.
   --  @param Content Exact standard-output content to write.
   --  @return True when output was accepted by the context and host.

   --  @param Context Invocation context to update.
   --  @param Path Redirection target path.
   --  @param Content Exact redirected output content to write.
   --  @param Append Whether append semantics are requested.
   --  @return Host redirection write status.
   function Write_File
     (Context : in out Invocation_Context;
      Path    : String;
      Content : String;
      Append  : Boolean) return Awk_CLI.Redirections.Write_Status;
   --  Record and materialize one redirected-output write for Context.
   --  @param Context Invocation context to update.
   --  @param Path Redirection target path.
   --  @param Content Exact redirected output content to write.
   --  @param Append Whether append semantics are requested.
   --  @return Host redirection write status.
end Awk_CLI.Context_IO;
