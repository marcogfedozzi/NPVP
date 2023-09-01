import lightning.pytorch as pl
from lightning.pytorch.callbacks import ModelCheckpoint
from lightning.pytorch.callbacks import Callback
from lightning.pytorch import loggers as pl_loggers
from lightning.pytorch.plugins import PrecisionPlugin
from lightning.pytorch.callbacks import TQDMProgressBar


from models import LitPredictor
from utils import LitDataModule, VisCallbackPredictor

import hydra
from hydra import compose, initialize
from omegaconf import DictConfig, OmegaConf
import argparse
from pathlib import Path

def parse_args():
    parser = argparse.ArgumentParser(description=globals()['__doc__'])
    parser.add_argument('--config_path', type=str, required=True, help='Path to configuration file')
    args = parser.parse_args()
    return args.config_path

@hydra.main(version_base=None, config_path="./configs", config_name="config")
def main(cfg : DictConfig) -> None:
    #save the code and config
    #save_code_cfg(cfg, cfg.Predictor.ckpt_save_dir)

    cfg = hydra.utils.instantiate(cfg)

    pl.seed_everything(cfg.Env.rand_seed, workers=True)
    #init model and dataloader
    data_module = LitDataModule(cfg)
    predictor = LitPredictor(cfg)

    #init logger and all callbacks
    checkpoint_callback = ModelCheckpoint(dirpath=cfg.Predictor.ckpt_save_dir, every_n_epochs = cfg.Predictor.log_per_epochs,
                                          save_top_k= cfg.Predictor.epochs, monitor = 'loss_val', filename= "Predictor-{epoch:02d}")
    if cfg.Env.visual_callback:
        callbacks = [VisCallbackPredictor(), checkpoint_callback]
    else:
        callbacks = [checkpoint_callback]

    callbacks.append(TQDMProgressBar(refresh_rate=10))


    tb_logger = pl_loggers.TensorBoardLogger(save_dir=cfg.Predictor.tensorboard_save_dir)
    trainer = pl.Trainer(
        #accelerator="gpu", devices=cfg.Env.world_size,
                         max_epochs=cfg.Predictor.epochs, enable_progress_bar=True, sync_batchnorm=True,
                         callbacks = callbacks, logger=tb_logger, strategy = cfg.Env.strategy,
                         check_val_every_n_epoch=10
                         )
    
    if cfg.Predictor.init_det_ckpt_for_vae is not None and cfg.Predictor.resume_ckpt is None:
        predictor = predictor.load_from_checkpoint(cfg = cfg, checkpoint_path=cfg.Predictor.init_det_ckpt_for_vae,
                                                   strict = False)

        trainer.fit(predictor, data_module)
    else:
        trainer.fit(predictor, data_module, ckpt_path=cfg.Predictor.resume_ckpt)

if __name__ == '__main__':
    main()