load("@bazel_skylib//:lib.bzl", "shell")

def _kind_cluster_impl(ctx):
    # That way we don't depend on defaults encoded in the binary but always
    # use defaults set on attributes of the rule
    args = [
        "-f=%s" % ctx.file.commands.short_path,
        "-k=%s" % str(ctx.attr.keep_going).lower(),
        "-types=%s" % ",".join(ctx.attr.types),
        "-eol-comments=%s" % str(ctx.attr.prefer_eol_comments).lower(),
        "-quiet=%s" % str(ctx.attr.quiet).lower(),
        "-edit-variables=%s" % str(ctx.attr.edit_variables).lower(),
        "-shorten_labels=%s" % str(ctx.attr.shorten_labels).lower(),
        "-delete_with_comments=%s" % str(ctx.attr.delete_with_comments).lower(),
    ]
    if ctx.file.tables:
        args.append("-tables=%s" % ctx.file.tables.short_path)
    if ctx.file.add_tables:
        args.append("-add_tables=%s" % ctx.file.add_tables.short_path)

    out_file = ctx.actions.declare_file(ctx.label.name + ".bash")
    substitutions = {
        "@@ARGS@@": shell.array_literal(args),
        "@@kind_cluster_SHORT_PATH@@": shell.quote(ctx.executable._kind_cluster.short_path),
        "@@ERROR_ON_NO_CHANGES@@": shell.quote(str(ctx.attr.error_on_no_changes).lower()),
    }
    ctx.actions.expand_template(
        template = ctx.file._runner,
        output = out_file,
        substitutions = substitutions,
        is_executable = True,
    )
    runfiles = ctx.runfiles(files = [ctx.executable._kind_cluster])
    return [DefaultInfo(
        files = depset([out_file]),
        runfiles = runfiles,
        executable = out_file,
    )]

_kind_cluster = rule(
    implementation = _kind_cluster_impl,
    attrs = {
        "commands": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "File to read commands from",
        ),
        "keep_going": attr.bool(
            doc = "Apply all commands, even if there are failures",
        ),
        "types": attr.string_list(
            doc = "List of rule types to change, the default empty list means all rules",
        ),
        "prefer_eol_comments": attr.bool(
            doc = "When adding a new comment, put it on the same line if possible",
            default = True,
        ),
        "quiet": attr.bool(
            doc = "Suppress informational messages",
        ),
        "edit_variables": attr.bool(
            doc = "For attributes that simply assign a variable (e.g. hdrs = LIB_HDRS), edit the build variable instead of appending to the attribute",
        ),
        "tables": attr.label(
            doc = "JSON file with custom table definitions which will replace the built-in tables",
            allow_single_file = True,
        ),
        "add_tables": attr.label(
            doc = "JSON file with custom table definitions which will be merged with the built-in tables",
            allow_single_file = True,
        ),
        "shorten_labels": attr.bool(
            doc = "Convert added labels to short form, e.g. //foo:bar => :bar",
            default = True,
        ),
        "delete_with_comments": attr.bool(
            doc = "If a list attribute should be deleted even if there is a comment attached to it",
            default = True,
        ),
        "error_on_no_changes": attr.bool(
            doc = "Exit with 3 on success, when no changes were made",
        ),
        "_kind_cluster": attr.label(
            default = "@io_sigs_k8s_kind//kind_cluster",
            cfg = "host",
            executable = True,
        ),
        "_runner": attr.label(
            default = "@com_github_atlassian_bazel_tools//kind_cluster:runner.bash.template",
            allow_single_file = True,
        ),
    },
    executable = True,
)

def kind_cluster(**kwargs):
    tags = kwargs.get("tags", [])
    if "manual" not in tags:
        tags.append("manual")
        kwargs["tags"] = tags
    _kind_cluster(
        **kwargs
    )
