# ── vite+ Config ──────────────────────────────────────────────────────────────
_scaffold_viteplus_config() {
  cat > vite.config.ts <<'EOF'
import { defineConfig } from "vite-plus";
import tsconfigPaths from "vite-tsconfig-paths";

export default defineConfig({
	staged: {
		"*": "vp check --fix",
	},
	plugins: [tsconfigPaths()],
	lint: {
		plugins: ["unicorn", "react", "jsx-a11y", "typescript", "oxc"],
		ignorePatterns: [
			"dist",
			"build",
			"public",
			"draco",
			"fonts",
			"assets",
			"migrations",
			"*.md",
			"*.env",
			"*env.example",
			"*.db",
		],
		options: {
			typeAware: true,
			typeCheck: true,
		},
		rules: {
			"react/no-danger": "error",
			"typescript/array-type": "warn",
			"typescript/ban-types": "error",
			"typescript/class-literal-property-style": "error",
			"typescript/consistent-type-assertions": "warn",
			"typescript/consistent-type-definitions": "error",
			"typescript/consistent-type-exports": "error",
			"typescript/consistent-type-imports": "error",
			"typescript/no-duplicate-enum-values": "error",
			"typescript/dot-notation": "error",
			"typescript/no-confusing-non-null-assertion": "error",
			"typescript/no-dynamic-delete": "error",
			"typescript/no-empty-interface": "warn",
			"typescript/no-explicit-any": "error",
			"typescript/prefer-for-of": "warn",
			"typescript/prefer-optional-chain": "warn",
			"typescript/prefer-readonly": "error",
			"typescript/prefer-readonly-parameter-types": "error",
			"typescript/prefer-nullish-coalescing": "warn",
			"typescript/prefer-return-this-type": "warn",
			"typescript/unified-signatures": "warn",
		},
	},
	fmt: {
		ignorePatterns: [
			"dist",
			"build",
			"public",
			"draco",
			"fonts",
			"migrations",
			"*.md",
			"*.env",
			"*env.example",
			"*.db",
		],
		printWidth: 80,
		useTabs: true,
		tabWidth: 4,
		semi: true,
		singleQuote: false,
		jsxSingleQuote: false,
		trailingComma: "all",
		arrowParens: "always",
		bracketSameLine: false,
		bracketSpacing: true,
		objectWrap: "preserve",
		experimentalSortImports: {
			groups: [
				// "sibling",
				// "parent",
				// "style",
				"external",
				"internal",
				// "type"
				// "builtin"
			],
			internalPattern: ["~/", "@/", "./", "../"],
			newlinesBetween: true,
			order: "asc",
		},
		experimentalSortPackageJson: {},
	},
})
EOF
}
