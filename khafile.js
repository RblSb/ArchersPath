let project = new Project("Archer's Path");
project.addAssets('res/**', {
	nameBaseDir: 'res',
	destination: '{dir}/{name}',
	name: '{dir}/{name}'
});
project.addSources('src');
project.addLibrary('thx.core');
project.addLibrary("edge");
project.addDefine('khmProps=game.CustomData.TileProps');
project.addParameter('-dce full');

resolve(project);
