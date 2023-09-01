import lightning.pytorch as pl
from lightning.pytorch.callbacks import ModelCheckpoint
from lightning.pytorch import loggers as pl_loggers
from lightning.pytorch.callbacks import TQDMProgressBar

from models import LitAE
from utils import LitDataModule, VisCallbackAE, save_code_cfg

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
    #save_code_cfg(cfg, cfg.AE.ckpt_save_dir)

    cfg = hydra.utils.instantiate(cfg)

    pl.seed_everything(cfg.Env.rand_seed, workers=True)
    #init model and dataloader
    data_module = LitDataModule(cfg)
    AE = LitAE(cfg)

    #init logger and all callbacks
    checkpoint_callback = ModelCheckpoint(dirpath=cfg.AE.ckpt_save_dir, every_n_epochs = cfg.AE.log_per_epochs,
                                          save_top_k=-1, save_last=True, monitor = 'L1_loss_valid', filename= "AE-{epoch:02d}")
    #callbacks = [VisCallbackAE(), checkpoint_callback]
    if cfg.Env.visual_callback:
        callbacks = [VisCallbackAE(), checkpoint_callback]
    else:
        callbacks = [checkpoint_callback]
    tb_logger = pl_loggers.TensorBoardLogger(save_dir=cfg.AE.tensorboard_save_dir)

    callbacks.append(TQDMProgressBar(refresh_rate=10))

    trainer = pl.Trainer(accelerator="gpu", devices=cfg.Env.world_size,
                         max_epochs=cfg.AE.epochs, enable_progress_bar=True, sync_batchnorm=True,
                         callbacks=callbacks, logger=tb_logger, strategy=cfg.Env.strategy,
                         check_val_every_n_epoch=10,
                         benchmark=True,
                         accumulate_grad_batches=cfg.Dataset.accumulate_grad_batches)
    trainer.fit(AE, data_module, ckpt_path=cfg.AE.resume_ckpt)

if __name__ == '__main__':

    main()

    #config_path = Path(parse_args())
    #initialize(version_base=None, config_path=str(config_path.parent))
    #cfg = compose(config_name=str(config_path.name))
#
    #main(cfg)