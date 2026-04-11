module ldtk

import json
import os

pub fn load(path string) !Project {
	raw := os.read_file(path) or { return error('LDtk: could not read file: ${path}') }
	project := json.decode(Project, raw) or { return error('LDtk: JSON parse failed: ${err}') }
	return project
}

// for projects with externalLevels = true, each level's layerInstances is null
// and lives in a sidecar .ldtkl file
// call this to hydrate a level in-place
pub fn load_external_level(level Level, project_dir string) !Level {
	rel := level.external_rel_path or {
		return error('LDtk: level "${level.identifier}" has no external path')
	}

	path := os.join_path(project_dir, rel)
	raw := os.read_file(path) or { return error('LDtk: could not read external level: ${path}') }
	return json.decode(Level, raw) or { return error('LDtk: failed to parse level: ${err}') }
}

// helper func to find a tileset definition by uid
pub fn (p &Project) tileset_by_uid(uid int) ?TilesetDef {
	for ts in p.defs.tilesets {
		if ts.uid == uid {
			return ts
		}
	}
	return none
}
