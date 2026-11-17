const fs = require("fs");
const [, , input, output] = process.argv;
const data = JSON.parse(fs.readFileSync(input, "utf8"));
const parents = data.parents;
const fps = 30;

function rows(w, x, y, z) {
	const n = Math.hypot(w, x, y, z);
	w /= n; x /= n; y /= n; z /= n;
	const r = (v) => Math.round(v * 1e6) / 1e6;
	return [
		[r(1 - 2 * (y * y + z * z)), r(2 * (x * y - w * z)), r(2 * (x * z + w * y))],
		[r(2 * (x * y + w * z)), r(1 - 2 * (x * x + z * z)), r(2 * (y * z - w * x))],
		[r(2 * (x * z - w * y)), r(2 * (y * z + w * x)), r(1 - 2 * (x * x + y * y))],
	];
}

function buildPose(name, frame) {
	const [px, py, pz, w, x, y, z] = frame[name];
	const children = Object.keys(parents)
		.filter((child) => parents[child] === name)
		.map((child) => buildPose(child, frame));
	const pose = {
		name,
		className: "Pose",
		properties: {
			CFrame: { CFrame: { position: [px, py, pz], orientation: rows(w, x, y, z) } },
			Weight: 1,
		},
	};
	if (children.length > 0) pose.children = children;
	return pose;
}

const root = Object.keys(parents).find((name) => parents[name] === null);
const keyframes = data.frames.map((frame, index) => ({
	name: "Keyframe",
	className: "Keyframe",
	properties: { Time: Math.round((index / fps) * 1e6) / 1e6 },
	children: [buildPose(root, frame)],
}));

const model = {
	className: "KeyframeSequence",
	properties: { Loop: true, Priority: "Action" },
	children: keyframes,
};
fs.writeFileSync(output, JSON.stringify(model, null, 1) + "\n");
console.log("keyframes", keyframes.length);
