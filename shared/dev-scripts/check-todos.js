import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";

/**
 * Detect TODO comments:
 * Scan all TypeScript files for TODO comments/types/function calls and displays them as warnings.
 *
 * Note: Never causes build fails, TODOs are info only.
 * Note: Auto-filters out JSDoc example lines to avoid false positives.
 *
 * @summary
 * - Types `TODO<"description">`
 * - Comments `TODO: description`
 * - Functions `TODO("description")`
 *
 */
const traverseFiles = (dir = "src") => {
	const files = [];

	const walk = (currentPath) => {
		try {
			const items = readdirSync(currentPath);

			items.forEach((item) => {
				const fullPath = join(currentPath, item);
				const stat = statSync(fullPath);

				if (stat.isDirectory()) {
					// Skip node_modules and hidden dirs
					if (item !== "node_modules" && !item.startsWith(".")) {
						walk(fullPath);
					}
				} else if (
					(item.endsWith(".ts") || item.endsWith(".tsx")) &&
					!item.endsWith(".d.ts")
				) {
					files.push(fullPath);
				}
			});
		} catch {
			// Skip inaccessible dirs
		}
	};

	walk(dir);
	return files;
};

const files = traverseFiles();
let todos = [];
let foundTodos = false;

files.forEach((file) => {
	try {
		const content = readFileSync(file, "utf-8");
		const lines = content.split("\n");

		lines.forEach((line) => {
			// Exclude JSDoc
			if (line.includes("@example")) {
				return;
			}

			/** `TODO<"description">` */
			const typeMatch = line.match(/TODO<["'](.+?)["']>/);
			if (typeMatch) {
				foundTodos = true;
				todos.push({ file, match: typeMatch[0], type: "type" });
				return;
			}

			/** `TODO: description` */
			const commentMatch = line.match(
				/TODO:\s*(.+?)(?:\s*$|(?=\*\/|\/\/))/,
			);
			if (commentMatch) {
				foundTodos = true;
				todos.push({
					file,
					match: `TODO: ${commentMatch[1].trim()}`,
					type: "comment",
				});
				return;
			}

			/** `TODO("description")` */
			const functionMatch = line.match(/TODO\(["'](.+?)["']\)/);
			if (functionMatch) {
				foundTodos = true;
				todos.push({
					file,
					match: `TODO("${functionMatch[1]}")`,
					type: "function",
				});
				return;
			}
		});
	} catch {
		// Skip inaccessible
	}
});

if (foundTodos) {
	console.group();
	todos.forEach(({ file, match, type }) => {
		console.warn(`\n⚠️  ${file}:`);
		console.warn(`   [${type}] ${match}`);
	});
	console.warn("");
	console.groupEnd();
}

process.exit(0);
