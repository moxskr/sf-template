const { defineConfig } = require('eslint/config');
const eslintJs = require('@eslint/js');
const jestPlugin = require('eslint-plugin-jest');
const lwcConfig = require('@salesforce/eslint-config-lwc/recommended');
const globals = require('globals');

module.exports = defineConfig([
	{
		ignores: ['**/*', '!force-app/**']
	},

	// LWC configuration
	{
		files: ['force-app/**/lwc/**/*.js'],
		extends: [lwcConfig]
	},

	// LWC configuration with override for LWC test files
	{
		files: ['force-app/**/lwc/**/*.test.js'],
		extends: [lwcConfig],
		rules: {
			'@lwc/lwc/no-unexpected-wire-adapter-usages': 'off'
		},
		languageOptions: {
			globals: {
				...globals.node
			}
		}
	},

	// Jest mocks configuration
	{
		files: ['force-app/**/jest-mocks/**/*.js'],
		languageOptions: {
			sourceType: 'module',
			ecmaVersion: 'latest',
			globals: {
				...globals.node,
				...globals.es2021,
				...jestPlugin.environments.globals.globals
			}
		},
		plugins: {
			eslintJs
		},
		extends: ['eslintJs/recommended']
	}
]);
